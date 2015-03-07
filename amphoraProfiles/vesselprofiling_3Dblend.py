import sys
import os
import struct

import numpy
import bpy



# Before we start clean up the default scene - remove all objects...
for name in bpy.data.objects.keys():
  bpy.data.objects[name].select = True
bpy.ops.object.delete()



# Get the filename we are loading, and determine if we are going to render an image later...
base_fn = sys.argv[sys.argv.index('--')+1]

try:
  render = sys.argv.index('render') > sys.argv.index('--')
except ValueError:
  render = False



# Read in the shp file...
f = open(base_fn + '.shp', 'rb')



## Some helper functions...
def read_big_int():
  return struct.unpack('>i', f.read(4))[0]

def read_little_int():
  return struct.unpack('<i', f.read(4))[0]

def read_little_short():
  return struct.unpack('<H', f.read(2))[0]

def read_double():
  return struct.unpack('d', f.read(8))[0]



## Header...
magic = read_big_int()
assert(magic==0x0000270a)

[read_big_int() for _ in range(5)]

length = 2 * read_big_int()
assert(length==os.path.getsize(base_fn + '.shp'))

version = read_little_int()
assert(version==1000)

shape_type = read_little_int()

min_x = read_double()
min_y = read_double()
max_x = read_double()
max_y = read_double()

min_z = read_double()
min_z = read_double()

min_m = read_double()
min_m = read_double()

print('Shapefile version = %i' % version)
print('Shapefile type = %i' % shape_type)
print('Shapefile range = [%f - %f] X [%f - %f]' % (min_x, max_x, min_y, max_y))



## Fields...
fields = {}
data_remaining = length - 100 # 100 is length of header.

while data_remaining>0:
  # Header for field...
  field_index = read_big_int()
  field_length = 2 * read_big_int()
  data_remaining -= 8
  
  # Read in the associated data...
  field_data = f.read(field_length)
  data_remaining -= field_length
  
  # Get the shape type...
  field_type = struct.unpack('<i', field_data[:4])[0]
  print('Field %i has type %i' % (field_index, field_type))
  
  # Load the data and cnvert to a format we can work with...
  if field_type==5:
    ## Simple, stuff...
    field_bound = struct.unpack('dddd', field_data[4:36])
    field_num_parts = struct.unpack('<i', field_data[36:40])[0]
    field_num_points = struct.unpack('<i', field_data[40:44])[0]
    
    print('  %i parts, %i points' % (field_num_parts, field_num_points))
    
    ## For efficiency load the arrays using numpy...
    field_parts = numpy.fromstring(field_data[44:44+4*field_num_parts], dtype=numpy.dtype('<i4'))
    field_points = numpy.fromstring(field_data[44+4*field_num_parts:], dtype=numpy.float64)
    field_points = field_points.reshape((-1, 2)) # [point, 0=x, 1=y]
    
    ## Break the points up into individual parts...
    field_parts = numpy.concatenate((field_parts, [field_num_points]))
    polygons = [field_points[field_parts[i]:field_parts[i+1]] for i in range(field_num_parts)]
    
    ## Record the field for later usage...
    fields[field_index] = dict()
    fields[field_index]['polygons'] = polygons
  
  else:
    print('Field type not supported by this loader - skipping')



## Clean up...
f.close()



# Read in the dbf file...
f = open(base_fn + '.dbf', 'rb')



## Header...
magic = struct.unpack('B', f.read(1))[0]
print('dBase: version code = %i' % (magic&0x07))
assert((magic&0x07)==3) # Have coded this for dBase level 5 only

last_edit = list(struct.unpack('BBB', f.read(3)))
last_edit[0] += 1900
print('dBase: last edit = %i-%i-%i' % tuple(last_edit))

records = read_little_int()
print('dBase: records = %i' % records)

header_size = read_little_short()
record_size = read_little_short()

print('dBase: header size = %i; record size = %i' % (header_size, record_size))

f.read(20) # Skip rest of main header



## Field array...
meta_fields = []

while True:
  start = struct.unpack('B', f.read(1))[0]
  if start==0x0D:
    break

  fname = chr(start) + ''.join([chr(c) for c in struct.unpack('10B', f.read(10)) if c!=0])
  ftype = struct.unpack('c', f.read(1))[0].decode('utf-8')
  f.read(4) # Skipping
  flength = struct.unpack('B', f.read(1))[0]
  fdec = struct.unpack('B', f.read(1))[0]
  f.read(14) # More skipping
  
  meta_fields.append({'index' : len(meta_fields)+1, 'name' : fname, 'type' : ftype, 'length' : flength, 'decimal' : fdec})
  
  print('dBase field %i: name = "%s", type = %s, length = %i' % (len(meta_fields), fname, ftype, flength))



## Read in actual data...
for record in range(1,records+1):
  for field in meta_fields:
    data = f.read(field['length'])
    if data[0]==ord(' ') and field['type']=='C':
      value = data[1:].decode('utf-8').strip()
      fields[record][field['name']] = value



## Clean up...
f.close()



# All data loaded - helper functions...
def prepare(type_name):
  """Loads all polygons with a given name into Blender as Mesh objects, returning a (potentially empty) list of objects that encapsulate the mesh objects."""
  ret = []
  
  for field in fields.values():
    if field['Type']==type_name:
      
      # Parts of the mesh...
      points = field['polygons'][0]
      
      verts = numpy.concatenate((points[:,0,numpy.newaxis], numpy.zeros(points.shape[0])[:, numpy.newaxis], points[:,1,numpy.newaxis]), axis=1)
      verts[verts[:,0]>0.0,0] = 0.0
      edges = list(zip(range(points.shape[0]-1), range(1, points.shape[0])))
      faces = []
      
      # Create the actual mesh object...
      mesh = bpy.data.meshes.new(type_name)
      mesh.from_pydata(verts, edges, faces)
      mesh.update()
      mesh.validate()
      
      # Setup the object...
      object = bpy.data.objects.new(type_name,  mesh)
      bpy.context.scene.objects.link(object)
      
      ret.append(object)
  
  return ret



# Load the external curve and lathe it into a surface...
body = prepare('External')[0]
parts = [body]

mod = body.modifiers.new('Screw', 'SCREW')
mod.use_normal_flip = True
mod.steps = 32
mod.render_steps = 64
  
mod = body.modifiers.new('Subdivision Surface', 'SUBSURF')



# Extract the handle section, or if its not avaliable create a circle; in both cases adjust the coordinates so that in the x axis they go from 0 to 1 and the y axis is zero mean...
cross_section = [field['polygons'][0] for field in fields.values() if field['Type']=='Handle section']

if len(cross_section)==0:
  # Just create a circle...
  ang = numpy.linspace(0.0, 2.0*numpy.pi, 33)
  cross_section = numpy.concatenate((numpy.sin(ang)[:,numpy.newxis], numpy.cos(ang)[:,numpy.newxis]), axis=1)

else:
  # Take first one as no clue what to do otherwise...
  cross_section = cross_section[0]
  
low = cross_section[:,0].min()
high = cross_section[:,0].max()
mean = cross_section[:,1].mean()

cross_section[:,0] = (cross_section[:,0] - low) / (high - low)
cross_section[:,1] = (cross_section[:,1] - mean) / (high - low)



# Process each handle curve in turn...
for field in fields.values():
  if field['Type']=='Handle':
    # Get the polygon...
    outline = field['polygons'][0]
    
    # The handle is one continuous curve - need to break it into 4 parts - outer, inner and the two that are touching the external surface - discover these breaks as the 4 largest changes in direction of the curve...
    change = numpy.empty(outline.shape[0]-1) # -1 because of duplicated point at end.
    for i in range(change.shape[0]):
      before = (i + change.shape[0] - 1) % change.shape[0]
      after = (i + 1) % change.shape[0]
      
      v1x = outline[before,0] - outline[i,0]
      v1y = outline[before,1] - outline[i,1]
      v2x = outline[after,0] - outline[i,0]
      v2y = outline[after,1] - outline[i,1]
      
      v1l = numpy.sqrt(v1x**2 + v1y**2)
      v2l = numpy.sqrt(v2x**2 + v2y**2)
      
      change[i] = (v1x*v2x + v1y*v2y) / (v1l * v2l)
    
    breaks = []
    for _ in range(4):
      v = numpy.argmax(change)
      change[v] = -1.0
      breaks.append(v)
    
    
    # Order the break indices, extract the segments...
    breaks.sort()
    
    curve = []
    curve.append(outline[breaks[0]:breaks[1]+1,:])
    curve.append(outline[breaks[1]:breaks[2]+1,:])
    curve.append(outline[breaks[2]:breaks[3]+1,:])
    curve.append(numpy.concatenate((outline[breaks[3]:change.shape[0],:], outline[0:breaks[0]+1,:]), axis=0))
    
    
    # There are two combinations - select the one that results in the longest overall length...
    length = numpy.zeros(4)
    for i in range(4):
      for j in range(curve[i].shape[0]-1):
        dx = curve[i][j+1,0] - curve[i][j,0]
        dy = curve[i][j+1,1] - curve[i][j,1]
        length[i] += numpy.sqrt(dx**2 + dy**2)

    if (length[0]+length[2]) > (length[1]+length[3]):
      # Length 0 and length 2 are the curves to use - longest gets to be outer, shortest inner...
      if length[0] > length[2]:
        outer = curve[0]
        inner = curve[2]
      else:
        outer = curve[2]
        inner = curve[0]
    
    else:
      # Length 1 and length 3 are the curves to use - longest gets to be outer, shortest inner...
      if length[1] > length[3]:
        outer = curve[1]
        inner = curve[3]
      else:
        outer = curve[3]
        inner = curve[1]
    
    
    # Define functions to get the locations on the two curves, based on length alone, so t goes from 0 to 1 - have not made any effort to be efficient about this, as not enough data to worry...
    def curve_pos(curve, t):
      lengths = numpy.sqrt(numpy.square(curve[1:,:] - curve[:-1,:]).sum(axis=1))
      
      total = numpy.cumsum(lengths)
      t *= total[-1]
      
      base = numpy.searchsorted(total, t)
      if (base+1)==total.shape[0]:
        base -= 1
      
      seg_t = (t - (total[base] - lengths[base])) / lengths[base]
      return (1.0-seg_t) * curve[base,:] + seg_t * curve[base+1,:]
    
    
    # Iterate and stitch together a sequence of curves - let Blender fix the edges so only do vertices and faces; need end caps...
    verts = []
    faces = []
    
    for t in numpy.linspace(0.0, 1.0, 96):
      start = curve_pos(outer, t)
      end = curve_pos(inner, 1.0-t)
      dist = numpy.sqrt(numpy.square(end - start).sum())
      
      cs = numpy.concatenate((cross_section[:,:], numpy.zeros((cross_section.shape[0],1))), axis=1)
      
      xt = cs[:,0].copy()
      cs[:,0] = (1.0 - xt) * start[numpy.newaxis,0] + xt * end[numpy.newaxis,0]
      cs[:,1] *= dist
      cs[:,2] = (1.0 - xt) * start[numpy.newaxis,1] + xt * end[numpy.newaxis,1]
      
      base = len(verts)
      for i in range(cs.shape[0]-1):
        verts.append((cs[i,0], cs[i,1], cs[i,2]))
      
      if t!=0.0:
        for i in range(cs.shape[0]-1):
          v1 = base+i
          v2 = base+(i+1)%(cs.shape[0]-1)
          v3 = v2 - (cs.shape[0]-1)
          v4 = v1 - (cs.shape[0]-1)
          faces.append((v1, v2, v3, v4))
          
    faces.append(tuple(range(cross_section.shape[0]-1)))
    faces.append(tuple(range(len(verts)-cross_section.shape[0]+1, len(verts))))
    
   
    # Make a mesh from the vertex and face cloud just created...
    mesh = bpy.data.meshes.new('Handle')
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    mesh.validate()
    
    mesh.polygons.foreach_set('use_smooth', [True] * len(faces))
      

    # Create an object for it...
    object = bpy.data.objects.new('Handle',  mesh)
    bpy.context.scene.objects.link(object)
    parts.append(object)



# Setup an orthographic camera at a suitable position...

## Bounding box calculation...
low  = numpy.zeros(3)
high = numpy.zeros(3)

for name in bpy.data.objects.keys():
  targ = bpy.data.objects[name]
  for corner in targ.bound_box:
    for coord in range(3):
      if low[coord] > corner[coord]:
        low[coord] = corner[coord]
      if high[coord] < corner[coord]:
        high[coord] = corner[coord]

## Setup an orthographic camera to match...
cam = bpy.data.cameras.new('Camera')
camera = bpy.data.objects.new('Camera', cam)
bpy.context.scene.objects.link(camera)
bpy.context.scene.camera = camera

camera.location = (0.0, -10.0, 0.0)
camera.rotation_euler[0] = numpy.pi*0.5

size_x = 2 * numpy.fabs(numpy.array([low[0],high[0]])).max()
size_z = 2 * numpy.fabs(numpy.array([low[2],high[2]])).max()
size = max(size_x, size_z)

cam.type = 'ORTHO'
cam.ortho_scale = size + 0.1

bpy.context.scene.render.resolution_x = int(1024 * (size_x / size))
bpy.context.scene.render.resolution_y = int(1024 * (size_z / size))
bpy.context.scene.render.resolution_percentage = 100



# Make sure we are in cycles, basic settings...
if not bpy.context.scene.render.engine == 'CYCLES':
  bpy.context.scene.render.engine = 'CYCLES'

bpy.data.worlds[0].horizon_color = (0.0, 0.0, 0.0)
bpy.context.scene.cycles.film_transparent = True

bpy.context.scene.cycles.use_square_samples = False
bpy.context.scene.cycles.samples = 400
bpy.context.scene.cycles.preview_samples = 100
bpy.context.scene.frame_end = 1

bpy.context.scene.render.filepath = '//' + os.path.basename(base_fn)



# Setup a material for the subject...
material = bpy.data.materials.new('Basic')
material.use_nodes = True
tree = material.node_tree

tree.links.clear()
tree.nodes.clear()

final = tree.nodes.new('ShaderNodeOutputMaterial')
final.location = 0, 0
        
mix = tree.nodes.new('ShaderNodeMixShader')
mix.location = -200, 0
mix.inputs[0].default_value = 0.2

diffuse = tree.nodes.new('ShaderNodeBsdfDiffuse')
diffuse.location = -400, -100

glossy = tree.nodes.new('ShaderNodeBsdfGlossy')
glossy.location = -400, 100

tree.links.new(mix.outputs[0], final.inputs[0])
tree.links.new(diffuse.outputs[0], mix.inputs[1])
tree.links.new(glossy.outputs[0], mix.inputs[2])

for part in parts:
  part.data.materials.append(material)



# Create a standard three point lighting rig...

## First we need a light source material...
light_mat = bpy.data.materials.new('Light')
light_mat.use_nodes = True
tree = light_mat.node_tree

tree.links.clear()
tree.nodes.clear()

final = tree.nodes.new('ShaderNodeOutputMaterial')
final.location = 0, 0
        
emission = tree.nodes.new('ShaderNodeEmission')
emission.location = -200, 0
emission.inputs[1].default_value = 5.0

tree.links.new(emission.outputs[0], final.inputs[0])


## Define a function for creating planes that face the origin, of a given size from the origin...
def make_plane(position, size, material):
  # Calculate a coordinate frame from the position...
  pos = numpy.asarray(position)
  norm = pos / numpy.sqrt(numpy.square(pos).sum())
  
  dx = numpy.zeros(3)
  dx[numpy.argmin(norm)] = 1.0
  
  dy = numpy.cross(dx, norm)
  dy /= numpy.sqrt(numpy.square(dy).sum())
  
  dx = numpy.cross(norm, dy)
  dx /= numpy.sqrt(numpy.square(dx).sum()) # Principally not required, but numerical precission makes it wise.

  # Use that to generate the 4 corners of the required plane...
  size *= 0.5
  p1 = tuple(pos + size * (dx + dy))
  p2 = tuple(pos + size * (dx - dy))
  p3 = tuple(pos + size * (-dx - dy))
  p4 = tuple(pos + size * (-dx + dy))
  
  # Create a mesh...
  mesh = bpy.data.meshes.new('Light')
  mesh.from_pydata([p1, p2, p3, p4], [], [(0,1,2,3)])
  mesh.update()
  mesh.validate()
  
  mesh.materials.append(material)
  
  # Create the object...
  object = bpy.data.objects.new('Light',  mesh)
  object.draw_type = 'WIRE'
  bpy.context.scene.objects.link(object)


## Create three lights in traditional positions...
make_plane((5.0,-3.0,3.0), 1, light_mat)
make_plane((-5.0,-5.0,0.0), 5, light_mat)
make_plane((-5.0,10.0,-2.0), 8, light_mat)



# Create a manifold mesh from the parts, that is simulation suitable - boolean followed by remesh...
man_object = bpy.data.objects.new('Manifold',  body.data)
bpy.context.scene.objects.link(man_object)

mod = man_object.modifiers.new('Screw', 'SCREW')
mod.use_normal_flip = True
mod.steps = 32
mod.render_steps = 64

mod = body.modifiers.new('Subdivision Surface', 'SUBSURF')

for part in parts[1:]:
  mod = man_object.modifiers.new('Add Handle', 'BOOLEAN')
  mod.object = part
  mod.operation = 'UNION'

mod = man_object.modifiers.new('Remesh', 'REMESH')
mod.mode = 'SMOOTH'
mod.octree_depth = 8
mod.use_smooth_shade = True



# Save out two .obj files - one with parts, one manifold...
bpy.ops.object.select_all(action='DESELECT')
for part in parts:
  part.select = True

bpy.ops.export_scene.obj(filepath=base_fn+'_seperate.obj', check_existing=False, use_selection=True, use_materials=False)

bpy.ops.object.select_all(action='DESELECT')
man_object.select = True

bpy.ops.export_scene.obj(filepath=base_fn+'_manifold.obj', check_existing=False, use_selection=True, use_materials=False)



# Done here to work around a weird bug; also deselect everything...
man_object.layers[1] = True
man_object.layers[0] = False

bpy.ops.object.select_all(action='DESELECT')



# Save out the .blend file...
bpy.ops.wm.save_as_mainfile(filepath=base_fn+'.blend')



# Optional code to render an image...
if render:
  bpy.ops.render.render(write_still=True)
