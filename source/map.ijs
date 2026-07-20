NB. map

NB. name;filename;sn;mt - sharename maptype
NB. return map info - returns 0 for had and mt
mapsub=: 3 : 0
'name fn sn ro'=. y
ts=. 1!:4 <fn NB. race here - get and map - OK to lose if file grows
if. IFUNIX do.
  'Unix sharename must be same as filename' assert (sn-:'')+.sn-:fn
  'FO FMP FMM'=. ro{mtflags NB. open flags, map prot flags, map map flags
  if. ('Darwin'-:UNAME) *. 'arm64'-:3 :'try.9!:56''cpu''catch.''''end.' '' do.
NB. apple m1/ios variadic parameters always passing on stack
  fh=. >0 { c_open_va fn;FO;(6#<00),<0
  else.
  fh=. >0 { c_open fn;FO;0
  end.
  'bad file name/access' assert fh~:_1
  mh=. ts NB.  unix doesn't use a mapping handle - use to hold fsize for unmap
  fad=. >0{ c_mmap (<0);ts;FMP;FMM;fh;0
  if. fad e. 0 _1 do. 'bad view' assert 0[free fh,mh,0 end.
else.
  'Win sharename must not have /' assert -.'/'e.sn
  'fa ma va'=. ro{mtflags NB. open/map/view flags
  NB. concurrent RO and RW require FILE_SHARE_WRITE+FILE_SHARE_READ for both

  NB. open can fail because of interference from other tasks (e.g., indexing)
  fh=. CreateFileR (uucp fn,{.a.);fa;(OR FILE_SHARE_WRITE, FILE_SHARE_READ);NULLPTR;OPEN_EXISTING;0;0
  if. fh=_1 do. NB. open can fail because of interference from other tasks (e.g., indexing)
   6!:3[2
   fh=. CreateFileR (uucp fn,{.a.);fa;(OR FILE_SHARE_WRITE, FILE_SHARE_READ);NULLPTR;OPEN_EXISTING;0;0
   'bad file name/access'assert fh~:_1
  end. 
  mh=: CreateFileMappingR fh;NULLPTR;ma;0;0;(0=#sn){(uucp sn,{.a.);<NULLPTR
  if. mh=0 do. 'bad mapping'assert 0[free fh,0,0 end.
  fad=. MapViewOfFileR mh;va;0;0;0
  if. fad=0 do.
    errno=. GetLastError''
    free fh,mh,0
    0 assert~;(8=errno){'bad view';'not enough memory'
  end.
end.
name;fn;sn;fh;mh;fad;0;ts;0;ro NB. had and jmf values still required
)

NB. =========================================================
NB.*map v map a file
NB. [type [,trailing_shape]] map name;filename [;sharename;ro]
map=: 3 : 0
0 map y
:
if. 0=L.x do. t=. <&> x else. t=. x end.
'type tshape hsize'=. 3 {. t, a:
type =. nountype type

'trailing shape may not be zero' assert -. 0 e. tshape

'name fn sn ro'=. 4{.y,(#y)}.'';'';'';0
fn=. jpath fn
sn=. '/' (('\'=sn)#i.#sn)} sn NB. / not allowed in win sharename
name=. fullname name
c=. #mappings

'maptype must be 0 (MTRW), 1 (MTRO), or 2 (MTCW - copy on write)' assert ro e. 0 1 2
'name already mapped'assert c=({."1 mappings)i.<name
'filename already mapped'assert c=(1{"1 mappings)i.<fn
'sharename already mapped'assert (''-:sn)+.c=(2{"1 mappings)i.<sn
4!:55 ::] <name
'bad noun name'assert ('_'={:name)*._1=nc<name
aa=. AFNJA+AFRO*ro=1       NB. readwrite/readonly array access

m=. mapsub name;fn;sn;ro
'fh mh fad had ts'=. (MAPFH,MAPMH,MAPADDRESS,MAPHEADER,MAPFSIZE){m

NB. File data has been mapped, not handle the J noun header.  If jmf=1 this is at the start of the user's file, otherwise we have to allocate
NB. a header and point it to the data.
NB. Before 9.8 the usecount of the header started at 2 so that it would not be deleted before it could be assigned (the name had here is the A block for an atomic INT that points to the actual header).
NB. This meant that aliasing was detected differently between normal and NJA blocks, which was ugly.
NB. Starting in 9.8 the header starts out with usecount 0 (zapped).  [(initc) is 1 for pre-9.8, 0 for 9.8].  The initial assignment to the mapname raises the usecount to 1, and the block is freed when its usecount goes to 0
NB. as the mapname is deleted.  To avoid getting the mapping and the usecount out of sync, the mapname is flagged as such and requests to delete the mapname are rejected if they don't come from our (unmap)
NB. verb.  Any attempt to unmap the file when there is an alias outstanding to the data is rejected.
if. ro*.0=type do. NB. readonly jmf file
  had=. allochdr 63
  d=. memr fad,0,HSN,JINT
  d=. (sfu HS+-/ufs fad,had),aa,2}.d NB. HADK HADFLAG
  d=. initc HADCN} d
  d setheader had
elseif. 0=type do.  NB. other jmf file
  had=. fad
  if. 0=validate ts,had do. 'bad jmf header' assert 0[free fh,mh,fad end.
  aa memw had,HADFLAG,1,JINT
  if. sn-:'' do.
    t=. 0
  else.
    t=. 10000+ getHADC had NB. shared ref count is bumped and is not valid
  end.
  (,t+initc) setHADC had
else.  NB. header is to be allocated as a J block
  had=. allochdr 63                    NB. allocate header
  'JBOXED (non-jmf) not supported' assert JBOXED~:type
  bx=. JBOXED=type
NB.  hs=. (+/hsize)*asize=. JSIZES {~ JTYPES i. type
NB. hsize should be in byte not atom, data knows nothing about items
  hs=. +/hsize [ asize=. JSIZES {~ JTYPES i. type
  lshape=. bx}.<.(ts-hs)%(*/tshape)*asize
  d=. sfu hs+-/ufs fad,had
  h=. d,aa,ts,type,initc,(*/lshape,tshape),((-.bx)+#tshape),lshape,tshape
  h setheader had  NB. set header
end.

m=. (had;0=type) (MAPHEADER,MAPJMF)}m
mappings=: mappings,m
if. -. initc do. (1{a.) memw had,(3 3 p. SZI),1,JCHAR end. NB. Install (ASGN>>24) into high byte of type as flag to indicate initial mapping
(name)=: 15!:7 had  NB. This increments usecount to initc+1
if. -. initc do. (0{a.) memw had,(3 3 p. SZI),1,JCHAR end. NB. Remove (ASGN>>24) flag
i.0 0
)

NB. intended for use in mtm where RO tasks must handle jmf file resize in RW task
NB. remap noun to get new filesize (resized in another task)
NB. Jd MTRO task gets new filesize set in MTRW task
NB. header not freed/allocated/changed - except to point at new address for data
NB. filesize option this could be used in Jd instead of unmap/map
remap=: 3 : 0
name=. fullname y
row=. ({."1 mappings)i.<name
'remap: not mapped' assert row<#mappings
m=. row{mappings
fn=. ;1{m
ro=.  >MAPMT{m  NB. mt - maptype - 0/ro/cow
jmf=. >MAPJMF{m
hs=. HS*jmf

NB. unmap so map can be done
'sn fh mh fad had'=. 5{.2}.m
free fh,mh,fad

NB. map to get new size
m=. mapsub name;fn;sn;ro
m=. (had;jmf) (MAPHEADER,MAPJMF)}m
mappings=: m row}mappings
fad=. >MAPADDRESS{m
d=. sfu hs+-/ufs fad,had
d memw had,HADK,1,JINT NB. header updated to point at data
((>MAPFSIZE{m)-hs) memw had,HADM,1,JINT NB. header updated with new msize
i.0 0
)

NB. =========================================================
NB.*share v share a mapped file
share=: 3 : 0
'name sn ro'=. 3{.y,<0
map name;sn;sn;ro
)
