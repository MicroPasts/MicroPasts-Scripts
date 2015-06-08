Overview
========

The vessel profiling 3D script generates a .json file of assorted statistics for each 3D model it writes, with `_stats.json` appended to the name of the shape file without extension.

Units are always metric, i.e. meters or cubic meters.

To ensure clarity the naming scheme for the various parts is given in naming_scheme.svg.



Statistics Saved
================

 * height - The height of the various parts (height.body, height.neck), plus the whole (height).

 * radius - The maximum radius around the axis of revolution of the amphora, given for the whole (radius) and the individual parts (radius.handle, radius.shell).

 * inner_radius - The radius inside the amphora - two values are given, the minimum at the neck (inner_radius.neck.min the radius of the largest object that can be inserted through the neck) and the maximum within the body (inner_radius.body.max).

 * thickness - The thickness of the shell, given as the minimum and maximum, with breakdown by part as well.

 * volume - The volume, also broken down by part and includes values for the cavity as well. Given the density of the ceramic and the contents total values could be calculated.

 * com - The centre of mass, as measured from the bottom of the amphora. Due to symmetry it can be assumed to lie on the axis of revolution. Broken up into the same set of parts as volume.

