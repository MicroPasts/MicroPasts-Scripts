# Copyright 2016 Tom SF Haines

# Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

#   http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

import sys
import os
import bpy



# Append the material from the materials.blend file...
material_path = sys.argv[sys.argv.index('--') + 1]

bpy.ops.wm.append(filepath=material_path+'/Material/Amphora', filename='Amphora', directory=material_path+'/Material/')



# Loop and swap all instances of 'Amphora' to 'Amphora.001'...
for obj in bpy.data.objects:
  if hasattr(obj.data, 'materials'):
    for i in range(len(obj.data.materials)):
      if obj.data.materials[i].name=='Amphora':
        obj.data.materials[i] = bpy.data.materials['Amphora.001']



# Change the output path, as its wrong in the original file...
_, parent_dir = os.path.split(os.path.dirname(bpy.data.filepath))
bpy.context.scene.render.filepath = '//' + parent_dir



# Tweak render settings down to something more civilised from the default...
bpy.context.scene.cycles.samples = 500



# Render...
bpy.ops.render.render(write_still=True)
