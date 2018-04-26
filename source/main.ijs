NB. jmf - main definitions except map,unmap
NB.
NB.  additem
NB.  createjmf
NB.  share
NB.  showle
NB.  showmap

NB. =========================================================
NB.*additem v add item to mapped noun
NB.
NB. no longer necessary, but retained for compatibility
additem=: 3 : 0
sad=. symget <fullname y
'bad name' assert sad
had=. 1{s=. memr sad,0 4,JINT
'flag msize type rank'=. 1 2 3 6{memr had,0 28,JINT
type =. nountype type 
'not mapped and writeable' assert 2=flag
'scalar' assert 0~:rank
'not supported for boxed data' assert 32~:type
shape=. memr had,HADS,rank,JINT
shape=. shape+1,0#~rank-1
size=. (JTYPES i.type){JSIZES
ts=. size**/shape
'msize too small' assert ts<:msize
((*/shape),rank,shape) memw had,HADN,(2+rank),JINT
i.0 0
)

NB. =========================================================
NB.*createjmf v create mapped file
NB. createjmf fn;msize
createjmf=: 3 : 0
'fn msize'=. y
msize=. <. msize
ts=. HS+msize     NB. total file size
if. IFUNIX do.
  fh=. 0 pick c_open fn; (OR O_RDWR, O_CREAT, O_TRUNC); 8b666
  c_lseek fh;(<:ts);SEEK_SET
  c_write fh; (,0{a.); 0+1   NB. place a single byte at the end
  c_lseek fh;0 ;SEEK_SET
  d=. HS,AFNJA,msize,JINT,0,0,1,0 NB. integer empty list
  c_write fh;d;(SZI*#d)
  c_close fh
else.
  fh=. CreateFileR (uucp fn,{.a.);(GENERIC_READ+GENERIC_WRITE);0;NULLPTR;CREATE_ALWAYS;0;0
  SetFilePointerR fh;ts;NULLPTR;FILE_BEGIN
  SetEndOfFile fh
  SetFilePointerR fh;0;NULLPTR;FILE_BEGIN
  d=. HS,AFNJA,msize,JINT,0,0,1,0 NB. integer empty list
  WriteFile fh;d;(SZI*#d);(,0);<NULLPTR
  CloseHandleR fh
end.
i.0 0
)

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
  mh=. OpenFileMappingR (ro{FILE_MAP_WRITE,FILE_MAP_READ);0;uucp sn,{.a.
  if. mh=0 do. assert 0[CloseHandleR fh['bad mapping' end.
  fad=. MapViewOfFileR mh;FILE_MAP_WRITE;0;0;0
  if. fad=0 do. assert 0[CloseHandleR mh[CloseHandleR fh['bad view' end.
  had=. fad
  hs=: 0
  ts=. memr had,HADM,1,JINT
  mappings=: mappings,name;fn;sn;fh;mh;fad;had;ts
  (name)=: symset had  NB. set name to address header
  i.0 0
end.
)

NB. =========================================================
getflagsad=: 3 : 0
SZI+1{memr (symget <fullname y),0 4,JINT
)

NB. =========================================================
readonly=: 3 : 0
AFRO(17 b.)memr (getflagsad y),0 1,JINT
:
flagsad=. getflagsad y
flags=. memr flagsad,0 1,JINT
flags=. flags(17 b.)(26 b.)AFRO NB. off AFRO
flags=. flags(23 b.)AFRO*0~:x
flags memw flagsad,0 1,JINT
i. 0 0
)

NB. =========================================================
showle=: 3 : 0
le=. memr (symget <fullname y),0 4,JINT
had=. 1{le
h=. memr had,0 7,JINT
s=. memr had,HADS,(6{h),JINT
le;h;s
)

NB. =========================================================
NB.*showmap v show all mappings
showmap=: 3 : 0
h=. 'name';'fn';'sn';'fh';'mh';'address';'header';'ts';'msize';'refs'
hads=. 6{"1 mappings
h,mappings,.(msize each hads),.refcount each hads
)
