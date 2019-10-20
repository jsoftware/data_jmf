
doc=: 0 : 0
map name;filename [;sharename [;mt] ]
 map jmf file (self-describing)

(type [;tshape]) map name;filename [;sharename [;mt] ]
 map data file

 types from dll.ijs: JB01,JCHAR,JCHAR2,JCHAR4,JINT,JFL,JCMPX,JSB

 tshape - trailing shape - }.shape    (default '')

mt (map type):
 0 - MTRW - default read/write mapping 
 1 - MTRO - read-only mapping - map jmf file copies header to private area
 2 - MTCW - copy-on-write - private mapping - changes not reflected in file

[force] unmap name - result 0 ok, 1 not mapped, 2 refs prevent unmap

createjmf filename;msize  - create jmf file as empty vector (self-describing)
unmapall''                - unmap all
showmap''                 - map info with col headers and extras
mappings                  - map info
share name;sharename[;mt] - share 'sharename' as name

MAPNAME,MAPFN,... showmap col indexes 
)
