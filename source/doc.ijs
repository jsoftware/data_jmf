
doc=: 0 : 0
map name;filename [;sharename;mt]
 map jmf file (self-describing)

opt map name;filename [;sharename;mt]
 map data file (opt is description)

 where:  opt=type [;trailing_shape]

 types defined in dll.ijs as: JB01,JCHAR,JCHAR2,JCHAR4,JINT,JFL,JCMPX,JSB

 trailing_shape= }. shape    (default '')

mt (map type):
 0 - MTRW  - default read/write mapping 
 1 - MTRO  - read-only mapping - map jmf file copies header to private area
 2 - MTCOW - copy-on-write - private mapping - changes not reflected in file

[force] unmap name - result 0 ok, 1 not mapped, 2 refs prevent unmap

unmapall''                  - unmap all
createjmf filename;msize    - creates jmf file as empty vector (self-describing)
share name;sharename[;mt]  - share 'sharename' as name
showmap''                   - map info with col headers and extra info
mappings                     - map info

MAPNAME,MAPFN,... showmap col indexes 
)
