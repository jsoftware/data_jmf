NB. unmap
NB.
NB.  unmap
NB.  unmapall

NB. =========================================================
NB.*unmap v unmap a mapped file
NB. [force] unmap name [;newsize] - 0 ok, 1 not mapped, 2 refs
NB. newsize excludes header size for jmf files
NB.
NB. newsize must be an increase in size
unmap=: 3 : 0
0 unmap y
:
'y newsize'=. 2{.(boxopen y),<_1
n=. <fullname y
row=. ({."1 mappings)i.n NB. row in mappings
if. row=#mappings do. 1 return. end.  NB. not mapped
m=. row{mappings
4!:55 ::] n NB. erase name
NB. 'sn fh mh fad had'=. 5{.2}.m
'sn fh mh fad had jmf ts'=. (MAPSN,MAPFH,MAPMH,MAPADDRESS,MAPHEADER,MAPJMF,,MAPFSIZE){m

if. *./(-.x),(0=#sn),1~:getHADC had do. 2 return. end.

NB. jmf=. fad = had  NB. if jmf (self-describing)
if. -.jmf do. freehdr had end.
if. _1=newsize do.
  free fh,mh,fad
else.
  newsize=. <.newsize
  totsize=. newsize + jmf*HS
  free _1,mh,fad
  if. IFUNIX do.
    if. totsize>ts do.
      c_lseek fh;(<:totsize);SEEK_SET
      c_write fh;(,0{a.);0+1 NB. place a single byte at the end
    elseif. totsize<ts do.
      c_ftruncate fh;totsize
    end.
    if. jmf do.
      c_lseek fh;(SZI*2);SEEK_SET
      c_write fh;(,newsize);SZI
    end.
    c_close fh
  else.
    SetFilePointerR fh;totsize;NULLPTR;FILE_BEGIN
    SetEndOfFile fh
    if. jmf do.
      SetFilePointerR fh;(SZI*2);NULLPTR;FILE_BEGIN
      WriteFile fh;(,newsize);SZI;(,0);<NULLPTR
    end.
    CloseHandleR fh
  end.
end.
mappings=: (row~:i.#mappings)#mappings
0
)

NB. =========================================================
NB.*unmapall v unmap all mapped files
NB. [force] unmapall dummy  - unmap all
unmapall=: 3 : '>unmap each 0{"1 mappings'
