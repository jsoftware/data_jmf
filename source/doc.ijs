
doc=: 0 : 0

 map name;filename [;sharename;readonly]
       - map jmf file (self-describing)

 opt map name;filename [;sharename;readonly]
       - map data file (opt is description)

     where:  opt=type [;trailing_shape]

        types are defined in dll.ijs as:
            JB01      boolean
            JCHAR     character
            JCHAR2    unicode
            JCHAR4    unicode4
            JINT      integer
            JFL       floating point
            JCMPX     complex
            JSB       symbol

         trailing_shape= }. shape    (default '')

 [force] unmap name
      0 ok
      1 not mapped
      2 refs

  unmapall''                  - unmap all

  createjmf filename;msize    - creates jmf file as empty vector
                                (self-describing)

  additem name                - add an item to a name

  share name;sharedname       - share 'sharedname' as name

  showle name                 - show locale entry and header for name

  showmap''                   - show all maps

)
