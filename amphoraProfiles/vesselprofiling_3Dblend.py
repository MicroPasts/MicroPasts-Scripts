# Copyright 2015 Tom SF Haines

# Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

#   http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

import sys
import os
import struct
import json

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

try:
  use_left = sys.argv.index('left') > sys.argv.index('--')
except ValueError:
  use_left = False

radial_ends = 0.2



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
      print('Field %i has %s=%s' % (record, field['name'], value))



## Clean up...
f.close()



# All data loaded - helper functions...
def prepare(type_name):
  """Loads all polygons with a given name into Blender as Mesh objects, returning a (potentially empty) list of objects that encapsulate the mesh objects."""
  ret = []
  
  for field in fields.values():
    if field['Type']==type_name:
      
      # Parts of the mesh...
      points = field['polygons'][0][:-1,:]
      
      verts = numpy.concatenate((points[:,0,numpy.newaxis], numpy.zeros(points.shape[0])[:, numpy.newaxis], points[:,1,numpy.newaxis]), axis=1)
      verts[verts[:,0]>0.0,0] = 0.0
      edges = list(zip(range(points.shape[0]-1), range(1, points.shape[0])))
      edges.append((points.shape[0]-1, 0))
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

if len(cross_section)==0 or cross_section[0].shape[0]<3:
  # Just create a circle...
  ang = numpy.linspace(0.0, 2.0*numpy.pi, 33)
  cross_section = numpy.concatenate((numpy.sin(ang)[:,numpy.newaxis], numpy.cos(ang)[:,numpy.newaxis]), axis=1)

else:
  # Take first one as no clue what to do otherwise...
  cross_section = cross_section[0]

cross_section = cross_section[:,1::-1] # Got the x and y coordinates the wrong way around - swapping them here is easier than correcting all of the below code.
cross_section[:,1] *= -1.0

low = cross_section[:,0].min()
high = cross_section[:,0].max()
mean = cross_section[:,1].mean()

cross_section[:,0] = (cross_section[:,0] - low) / (high - low)
cross_section[:,1] = (cross_section[:,1] - mean) / (high - low)



# Process each handle curve in turn...
handle_fields = [field for field in fields.values() if field['Type'] in ['Handle', 'Left Handle', 'Right Handle']]

for field in handle_fields:
  # Get the polygon...
  outline = field['polygons'][0]
    
  # If its the right handle and we are meant to be using the left make the swap...
  if use_left and (outline[:,0] > 0.0).all():
    other = [f for f in handle_fields if id(f)!=id(field)][0]
    outline = other['polygons'][0].copy()
    outline[:,0] *= -1.0
    outline = outline[::-1,:]
    
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
    caps = curve[1], curve[3]
    if length[0] > length[2]:
      outer = curve[0]
      inner = curve[2]
    else:
      outer = curve[2]
      inner = curve[0]
    
  else:
    # Length 1 and length 3 are the curves to use - longest gets to be outer, shortest inner...
    caps = curve[0], curve[2]
    if length[1] > length[3]:
      outer = curve[1]
      inner = curve[3]
    else:
      outer = curve[3]
      inner = curve[1]
    
    
  # Create inner and outer curves as no-face meshes, on layer 3, for diagnostic purposes...
  inner_vert = numpy.concatenate((inner[:,0,numpy.newaxis], numpy.zeros((inner.shape[0],1), dtype=numpy.float32), inner[:,1,numpy.newaxis]), axis=1)
  inner_edge = numpy.concatenate((numpy.arange(0,inner.shape[0]-1)[:,numpy.newaxis], numpy.arange(1,inner.shape[0])[:,numpy.newaxis]), axis=1)
    
  inner_mesh = bpy.data.meshes.new('Inner')
  inner_mesh.from_pydata(inner_vert, inner_edge, [])
  inner_mesh.update()
  inner_mesh.validate()
    
  inner_object = bpy.data.objects.new('Inner', inner_mesh)
  bpy.context.scene.objects.link(inner_object)
    
  inner_object.layers[2] = True
  inner_object.layers[0] = False
    
  outer_vert = numpy.concatenate((outer[:,0,numpy.newaxis], numpy.zeros((outer.shape[0],1), dtype=numpy.float32), outer[:,1,numpy.newaxis]), axis=1)
  outer_edge = numpy.concatenate((numpy.arange(0,outer.shape[0]-1)[:,numpy.newaxis], numpy.arange(1,outer.shape[0])[:,numpy.newaxis]), axis=1)
    
  outer_mesh = bpy.data.meshes.new('Outer')
  outer_mesh.from_pydata(outer_vert, outer_edge, [])
  outer_mesh.update()
  outer_mesh.validate()
    
  outer_object = bpy.data.objects.new('Outer', outer_mesh)
  bpy.context.scene.objects.link(outer_object)
    
  outer_object.layers[2] = True
  outer_object.layers[0] = False
    
  for c, cap in enumerate(caps):
    cap_vert = numpy.concatenate((cap[:,0,numpy.newaxis], numpy.zeros((cap.shape[0],1), dtype=numpy.float32), cap[:,1,numpy.newaxis]), axis=1)
    
    cap_mesh = bpy.data.meshes.new('Cap')
    cap_mesh.from_pydata(cap_vert, [], [])
    cap_mesh.update()
    cap_mesh.validate()
    
    cap_object = bpy.data.objects.new('Cap', cap_mesh)
    bpy.context.scene.objects.link(cap_object)
    
    cap_object.layers[2] = True
    cap_object.layers[0] = False
    
    
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
    
    
  # Iterate and stitch together a sequence of curves - let Blender fix the edges so only do vertices and faces...
  verts = []
  faces = []
    
  for t in numpy.linspace(0.0, 1.0, 96):
    # Get the inner and outer position between which we will interpolate the 
    start = curve_pos(outer, t)
    end = curve_pos(inner, 1.0-t)
    dist = numpy.sqrt(numpy.square(end - start).sum())
      
    # Copy the cross section, with an additional third dimension...
    cs = numpy.concatenate((cross_section[:,:], numpy.zeros((cross_section.shape[0],1))), axis=1)
      
    # Calculate the coordinates of the vertices from positioning the cross scetion between the inner and outer curve at the current position...
    xt = cs[:,0].copy()
    cs[:,0] = (1.0 - xt) * start[numpy.newaxis,0] + xt * end[numpy.newaxis,0]
    cs[:,1] *= dist
    cs[:,2] = (1.0 - xt) * start[numpy.newaxis,1] + xt * end[numpy.newaxis,1]
      
    # If close to the end of the handle interpolate towards radial coordinates, to make sure we get a clean join...
    if (t<radial_ends) or ((1.0-t)<radial_ends):
      amount = (t / radial_ends) if t<radial_ends else ((1.0-t) / radial_ends)
        
      ratio = numpy.fabs(cs[:,0]) / numpy.sqrt(numpy.square(cs[:,:2]).sum(axis=1))
        
      ratio = numpy.exp(numpy.log(ratio) * (1.0-amount)) # Interpolation bit - looks weird but makes sense if you think amount it!
        
      cs[:,:2] *= ratio[:,numpy.newaxis]
      
    # Add the vertices to the mesh...
    base = len(verts)
    for i in range(cs.shape[0]-1):
      verts.append((cs[i,0], cs[i,1], cs[i,2]))
      
    # If there are previous rings of vertices add in the faces needed to stitch this ring to the previous...
    if t!=0.0:
      for i in range(cs.shape[0]-1):
        v1 = base+i
        v2 = base+(i+1)%(cs.shape[0]-1)
        v3 = v2 - (cs.shape[0]-1)
        v4 = v1 - (cs.shape[0]-1)
        faces.append((v1, v2, v3, v4))
    
    
  # Add end caps so its a sealed mesh...
  #faces.append(tuple(range(cross_section.shape[0]-1)))
  #faces.append(tuple(range(len(verts)-cross_section.shape[0]+1, len(verts))))
    
   
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



# Append a material for the subject...
bpy.ops.wm.append(filepath='//materials.blend/Material/Amphora', filename='Amphora', directory=os.path.join(os.path.dirname(__file__), 'materials.blend') + '/Material/')

material = bpy.data.materials['Amphora']

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



# Write out some stats to a .json file...
stats = {}

## Dimensions...
def radius_object(name):
  targ = bpy.data.objects[name]
  radius = 0.0
  for corner in targ.bound_box:
    for coord in range(2):
      val = numpy.fabs(corner[coord])
      if val>radius:
        radius = val
  
  return radius

stats['height'] = high[2] - low[2]
stats['radius.handle'] = radius_object('Handle')
stats['radius.shell'] = radius_object('External')
stats['radius'] = max(stats['radius.handle'], stats['radius.shell'])


## Neck join height...
neck_join_height = None
for field in fields.values():
  if field['Type']=='Neck join':
    neck_join_height = field['polygons'][0][:,1].min()

if neck_join_height!=None:
  stats['height.neck'] = high[2] - neck_join_height
  stats['height.body'] = neck_join_height - low[2]


## Function to calculate the volume and center of mass of a sequence of points that are lathed - [:,0] are distances from the axis, [:,1] are position along the axis. Outputs two values of each - one for the positive direction parts, another for the negative. This allows you to calculate both relevant numbers...
def vol_com(line):
  vol = [0.0, 0.0] # Note that this doubles as weight for the incrimental mean in com.
  com = [0.0, 0.0]
  
  for i in range(line.shape[0]-1):
    if line[i,1] > line[i+1,1]:
      a = numpy.fabs(line[i+1,0])
      b = numpy.fabs(line[i,0])
      c = line[i,1] - line[i+1,1]
      bottom = line[i+1,1]
      oi = 0
    else:
      a = numpy.fabs(line[i,0])
      b = numpy.fabs(line[i+1,0])
      c = line[i+1,1] - line[i,1]
      bottom = line[i,1]
      oi = 1
    
    v = numpy.pi * c * (a*a + a*b + b*b) / 3.0 # Volume of lathed slice.
    if v>1e-6: # Zero volume would cause a divide by zero for centre of mass calculation.
      m = bottom + numpy.pi * c * c * (a*a / 12.0 + a*b / 6.0 + b*b / 4.0) / v # Center of mass.
      
      # Incrimental mean update...
      vol[oi] += v
      com[oi] += (m - com[oi]) * v / vol[oi]
  
  return vol, com


## Given a line for lathing this determines the maximum and minimum thickness, as seen from the axis of revolution...
def thickness(line):
  # For every point try and find its neighbouring line segment, intercept, and use that to determine the thickness...
  depths = []
  
  for i in range(line.shape[0]):
    # Check if a line extending from this vertex is horizontal - if so then its length is the thickness...
    if i!=0 and numpy.fabs(line[i-1,1] - line[i,1])<1e-6:
      depths.append(numpy.fabs(line[i-1,0] - line[i,0]))
      continue
    
    if i+1<line.shape[0] and numpy.fabs(line[i,1] - line[i+1,1])<1e-6:
      depths.append(numpy.fabs(line[i,0] - line[i+1,0]))
      continue
    
    # Check all line segments that don't include this vertex - numbers aren't high enough to care that this is O(n^2)...
    for j in range(line.shape[0]-1):
      if ((j>=i-1) and (j<=i+1)) or (i==0 and j==(line.shape[0]-2)):
        continue # Line segment includes current vertex.
      
      if (line[j,1]<line[i,1]) != (line[j+1,1]<line[i,1]):
        # Intersect - find out and record exact thickness...
        t = (line[i,1] - line[j,1]) / (line[j+1,1] - line[j,1])
        val = (1-t) * line[j,0] + t * line[j+1,0]
        depths.append(numpy.fabs(line[i,0] - val))
  
  return numpy.min(depths), numpy.max(depths)


## Calculates the minimum and maximum inner radius...
def inner_radius(line):
  # For every point try and find its neighbouring line segment, intercept, and use that to determine if its inner or outer - ignore if outer...
  rads = []
  
  for i in range(line.shape[0]):
    # Check if a line extending from this vertex is horizontal - if so then take the minimum of the two as the inner radius at this point...
    if i!=0 and numpy.fabs(line[i-1,1] - line[i,1])<1e-6:
      rads.append(min(numpy.fabs(line[i-1,0]), numpy.fabs(line[i,0])))
      continue
    
    if i+1<line.shape[0] and numpy.fabs(line[i,1] - line[i+1,1])<1e-6:
      rads.append(min(numpy.fabs(line[i,0]), numpy.fabs(line[i+1,0])))
      continue
    
    # Check all line segments that don't include this vertex - numbers aren't high enough to care that this is O(n^2)...
    for j in range(line.shape[0]-1):
      if ((j>=i-1) and (j<=i+1)) or (i==0 and j==(line.shape[0]-2)):
        continue # Line segment includes current vertex.
      
      if (line[j,1]<line[i,1]) != (line[j+1,1]<line[i,1]):
        # Intersect - select the one with the lowest absolute value as the inner radius...
        t = (line[i,1] - line[j,1]) / (line[j+1,1] - line[j,1])
        val = (1-t) * line[j,0] + t * line[j+1,0]
        rads.append(min(numpy.fabs(line[i,0]), numpy.fabs(val)))
  
  return numpy.min(rads), numpy.max(rads)


## Function to clip a lathed line sequence between two heights; can use None for infinity...
def clip_line(line, low=None, high=None):
  output = []
  prev_clipped = None
  
  for i in range(line.shape[0]):
    # Detect if we are cliping...
    clip = False
    if low!=None and line[i,1]<low:
      clip = True
      intercept = low
    if high!=None and line[i,1]>high:
      clip = True
      intercept = high
    
    # If clip has changed truthiness we need to omit an intercept point; note the abuse of None for the start of the loop with prev_clipped...
    if (clip and prev_clipped==False) or (not clip and prev_clipped==True):
        # Intercept and omit a point on the clip line between this and the previous point...
        t = (intercept - line[i-1,1]) / (line[i,1] - line[i-1,1])
        rad = (1-t) * line[i-1,0] + t * line[i,0]
        output.append((rad, intercept))
    
    # Omit this point if not clipped...
    if not clip:
      output.append((line[i,0], line[i,1]))
    
    # Prepare for next loop...
    prev_clipped = clip
  
  return numpy.array(output, dtype=numpy.float32)


## Calculate the volumes...
for field in fields.values():
  if field['Type']=='External':
    line = field['polygons'][0]
    vol, com = vol_com(line)
    
    max_i = numpy.argmax(vol)
    min_i = numpy.argmin(vol)
    stats['volume.shell'] = vol[max_i] - vol[min_i]
    stats['volume.cavity'] = vol[min_i] # Assumption here that the cavity doesn't go back on itself as viewed from the lathing axis. I think this is reasonable, as such an amphora would be hard to make and highly impractical.
    
    stats['com.shell'] = ((com[max_i]*vol[max_i] - com[min_i]*vol[min_i]) / (vol[max_i] - vol[min_i])) - low[2]
    stats['com.cavity'] = com[min_i] - low[2]
    
    if neck_join_height!=None:
      neck = clip_line(line, low=neck_join_height)
      body = clip_line(line, high=neck_join_height)
      
      vol, com = vol_com(neck)
      max_i = numpy.argmax(vol)
      min_i = numpy.argmin(vol)
      stats['volume.neck.shell'] = vol[max_i] - vol[min_i]
      stats['volume.neck.cavity'] = vol[min_i]
      stats['com.neck.shell'] = ((com[max_i]*vol[max_i] - com[min_i]*vol[min_i]) / (vol[max_i] - vol[min_i])) - low[2]
      stats['com.neck.cavity'] = com[min_i] - low[2]
      
      vol, com = vol_com(body)
      max_i = numpy.argmax(vol)
      min_i = numpy.argmin(vol)
      stats['volume.body.shell'] = vol[max_i] - vol[min_i]
      stats['volume.body.cavity'] = vol[min_i]
      stats['com.body.shell'] = ((com[max_i]*vol[max_i] - com[min_i]*vol[min_i]) / (vol[max_i] - vol[min_i])) - low[2]
      stats['com.body.cavity'] = com[min_i] - low[2]


## Calculate the minimum and maximum thicknesses of the shell...
for field in fields.values():
  if field['Type']=='External':
    line = field['polygons'][0]
    stats['thickness.min'], stats['thickness.max'] = thickness(line)
    
    if neck_join_height!=None:
      neck = clip_line(line, low=neck_join_height)
      body = clip_line(line, high=neck_join_height)

      stats['thickness.body.min'], stats['thickness.body.max'] = thickness(body)
      stats['thickness.neck.min'], stats['thickness.neck.max'] = thickness(neck)


## The minimum radius of the neck and the maximum radius of the body...
if neck_join_height!=None:
  for field in fields.values():
    if field['Type']=='External':
      line = field['polygons'][0]
      neck = clip_line(line, low=neck_join_height)
      body = clip_line(line, high=neck_join_height)
      
      stats['inner_radius.neck.min'], _ = inner_radius(neck)
      _, stats['inner_radius.body.max'] = inner_radius(body)


## Write the file...
sf = open(base_fn + '_stats.json', 'w')
sf.write(json.dumps(stats, indent = 2, sort_keys=True))
sf.close()



# Optional code to render an image...
if render:
  bpy.ops.render.render(write_still=True)
