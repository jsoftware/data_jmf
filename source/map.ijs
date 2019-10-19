NB. map

NB. name;filename;sn;mt - sharename maptype
NB. return map info - returns 0 for had and mt
mapsub=: 3 : 0
'name fn sn ro'=. y
ts=. 1!:4 <fn NB. race here - get and map - OK to lose if file grows
if. IFUNIX do.
  'Unix sharename must be same as filename' assert (sn-:'')+.sn-:fn
  'FO FMP FMM'=. ro{mtflags NB. open flags, map prot flags, map map flags
  fh=. >0 { c_open fn;FO;0
  'bad file name/access' assert fh~:_1
  mh=. ts NB.  unix doesn't use a mapping handle - use to hold fsize for unmap
  fad=. >0{ c_mmap (<0);ts;FMP;FMM;fh;0
  if. fad e. 0 _1 do. 'bad view' assert 0[free fh,mh,0 end.
else.
  'fa ma va'=. ro{RW     NB. readwrite/readonly for file, map, view access
  NB. concurrent RO and RW require FILE_SHARE_WRITE+FILE_SHARE_READ for both
  fh=. CreateFileR (uucp fn,{.a.);fa;(OR FILE_SHARE_WRITE, FILE_SHARE_READ);NULLPTR;OPEN_EXISTING;0;0
  'bad file name/access'assert fh~:_1
  mh=: CreateFileMappingR fh;NULLPTR;ma;0;0;(0=#sn){(uucp sn,{.a.);<NULLPTR
  if. mh=0 do. 'bad mapping'assert 0[free fh,0,0 end.
  fad=. MapViewOfFileR mh;va;0;0;0
  if. fad=0 do.
    errno=. GetLastError''
    free fh,mh,0
    if. ERROR_NOT_ENOUGH_MEMORY-:errno do.
      'not enough memory' assert 0
    else.
      'bad view' assert 0
    end.
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

'maptype must be 0 (normal), 1 (readonly), or 2 (COW - copy on write)' assert ro e. 0 1 2
'name already mapped'assert c=({."1 mappings)i.<name
'filename already mapped'assert c=(1{"1 mappings)i.<fn
'sharename already mapped'assert (''-:sn)+.c=(2{"1 mappings)i.<sn
4!:55 ::] <name
'bad noun name'assert ('_'={:name)*._1=nc<name
aa=. AFNJA+AFRO*ro=1       NB. readwrite/readonly array access

m=. mapsub name;fn;sn;ro
'fad had ts'=. (MAPADDRESS,MAPHEADER,MAPFSIZE){m

if. ro*.0=type do. NB. readonly jmf file
  had=. allochdr 127
  d=. memr fad,0,HSN,JINT
  d=. (sfu HS+-/ufs fad,had),aa,2}.d NB. HADK HADFLAG
  d=. 1 HADCN} d
  d setheader had
elseif. 0=type do.
  had=. fad
  if. 0=validate ts,had do. 'bad jmf header' assert 0[free fh,mh,fad end.
  aa memw had,HADFLAG,1,JINT
  if. sn-:'' do.
    t=. 0
  else.
    t=. 10000+ getHADC had NB. shared ref count is bumped and is not valid
  end.
  (,t+1) setHADC had    NB. ref count is 1 (except for shared, which is bumped)
elseif. 1 do.
  had=. allochdr 127                   NB. allocate header
  'JBOXED (non-jmf) not supported' assert JBOXED~:type
  bx=. JBOXED=type
NB.  hs=. (+/hsize)*asize=. JSIZES {~ JTYPES i. type
NB. hsize should be in byte not atom, data knows nothing about items
  hs=. +/hsize [ asize=. JSIZES {~ JTYPES i. type
  lshape=. bx}.<.(ts-hs)%(*/tshape)*asize
  d=. sfu hs+-/ufs fad,had
  h=. d,aa,ts,type,1,(*/lshape,tshape),((-.bx)+#tshape),lshape,tshape
  h setheader had  NB. set header
end.

m=. (had;0=type) (MAPHEADER,MAPJMF)}m
mappings=: mappings,m
(name)=: symset had  NB. set name to address header
i.0 0
)

NB. remap noun to get new filesize (resized in another task)
NB. Jd uses in JdMTM - RO task gets new filesize set in WR task
NB. duplicates code from unmap and map
NB. header not freed/allocated/changed - except to point at new address for data
NB. with new filesize option this could be used in Jd instead of unmap/map
NB. HS used to set header new data address assumes jmf or jmf-ro
remap=: 3 : 0
name=. fullname y
row=. ({."1 mappings)i.<name
'not mapped' assert row<#mappings
m=. row{mappings
fn=. ;1{m
jmf=. >MAPJMF{m  NB. jmf
ro=.  >MAPMT{m  NB. mt - maptype - 0/ro/cow

NB. unmap so map can be done
'sn fh mh fad had'=. 5{.2}.m
free fh,mh,fad

NB. map to get possible new size
m=. mapsub name;fn;sn;ro
m=. (had;jmf) (MAPHEADER,MAPJMF)}m
mappings=: m row}mappings
if. -.jmf do.
 fad=. >MAPADDRESS{m
 d=. sfu HS+-/ufs fad,had
 d memw had,0,1,JINT NB. header updated to point at possibly new data
end.
i.0 0
)

NB.! should use mapsub
NB. =========================================================
NB.*share v share a mapped file
share=: 3 : 0
'name sn ro'=. 3{.y,<0
sn=. '/' (('\'=sn)#i.#sn)} sn NB. / not allowed in win sharename
if. IFUNIX do.
  map name;sn;sn;ro
else.
  name=. fullname name
  c=. #mappings
  assert c=({."1 mappings)i.<name['noun already mapped'
  4!:55 ::] <name
  'bad noun name'assert ('_'={:name)*._1=nc<name
  fh=. _1
  fn=. ''
  mh=. OpenFileMappingR (ro{FILE_MAP_WRITE,FILE_MAP_READ);0;uucp sn,{.a. NB. copy
  if. mh=0 do. assert 0[CloseHandleR fh['bad mapping' end.
  fad=. MapViewOfFileR mh;(ro{FILE_MAP_WRITE,FILE_MAP_READ);0;0;0 NB. copy
  if. fad=0 do. assert 0[CloseHandleR mh[CloseHandleR fh['bad view' end.
  had=. fad
  hs=: 0
  ts=. gethadmsize had
  mappings=: mappings,name;fn;sn;fh;mh;fad;had;ts
  (name)=: symset had  NB. set name to address header
  i.0 0
end.
)
