NB. jmf api

NB. following will eventually be defined in stdlib
memhad_z_=: [: {: [: memr 0 2 4 ,~ (15!:6)@< NB. header address from name (904 15!:12)
memdad_z_=: 15!:14@< NB. data address from name

0 : 0
807 made changes to the header that affect jmf J code
before 807 - HADR field bytes are (lilendian) rrrr (j32) rrrrrrrr (j64)
after  807 - HADR field bytes are (lilendian) rrhh (j32) rrhhxxxx (j64)
flipped for bigendian (fill,hh,rr)
hh field flags must not be touched by jmf
newheader is 1 if 807 header format
)
IFBE=: 'a'~:{.2 ic a.i.'a'
SZI=: IF64{4 8     NB. sizeof integer - 4 for 32 bit and 8 for 64 bit

NB. index into mappings/showmap - MAPMSIZE and MAPREFS only in showmap
'MAPNAME MAPFN MAPSN MAPFH MAPMH MAPADDRESS MAPHEADER MAPFSIZE MAPJMF MAPMT MAPMSIZE MAPREFS'=: i.12

NB. mt - maptype
'MTRW MTRO MTCW'=: i.3 NB. normal, read-only, copy on write

NB. J array header byte offsets
NB. offset flag msize type refcnt elementcnt rank shap
'HADK HADFLAG HADM HADT HADC HADN HADR HADS'=: SZI*i.8
HADRUS=: HADR+IFBE*IF64{2 6 NB. address of rank US bytes
HADCN=: <.HADC%SZI
HSN=: 7+64         NB. jmf header size in JINTs
HS=: SZI*HSN       NB. jmf header size in bytes
AFRO=: 1           NB. header flag - readonly
AFNJA=: 2          NB. header flag - non-J allocation
NULLPTR=: <0
NB. must set HADC in same sentence as 15!:8 !!!
allochdr=: 3 : 'r[2 setHADC r=.15!:8 y'
freehdr=: 15!:9 NB. free header
msize=: gethadmsize=: 3 : 'memr y,HADM,1,JINT'
fullname=: 3 : 0
t=. y-.' '
t,('_'~:{:t)#'_base_'
)
newheader=: 0~:memr (memhad'SZI_jmf_'),HADR,1,JINT

setheader=: 4 : 0
if. newheader do.
 (6{.x) memw y,0,6,JINT
 (6{x)  setHADR y
 (7}.x) memw y,HADS,(#7}.x),JINT
else.
 x memw y,0,(#x),JINT
end.
)

getHADR=: 3 : 0
if. newheader do.
 _1 (3!:4) memr y,HADRUS,2,JCHAR
else.
 memr y,HADR,1,JINT
end.
)

setHADR=: 4 : 0
if. newheader do.
 (1 (3!:4) x) memw y,HADRUS,2,JCHAR
else.
 x memw y,HADR,1,JINT
end.
)

getHADC=: 3 : '  memr y,HADC,1,JINT'
setHADC=: 4 : 'x memw y,HADC,1,JINT'
refcount=: getHADC


NB. =========================================================
NB. conditional definitions
3 : 0''
if. IFUNIX do.
  lib=. ' ',~ unxlib 'c'
  api=. 1 : ('(''',lib,''',m) & cd')
  c_open=: 'open i *c i i' api
  c_open_va=: 'open i *c i x x x x x x i' api
  c_close=: 'close i i' api
  c_read=: 'read x i * x' api
  c_write=: 'write x i * x' api
  c_lseek=: 'lseek x i x i' api
  c_ftruncate=: 'ftruncate i i x' api
  c_mmap=: 'mmap * * x i i i x' api
  c_munmap=: 'munmap i * x' api
  NB.           c_open    c_mmap-prot              c_mmap-map
  t=.           O_RDWR,   (PROT_WRITE+PROT_READ),  MAP_SHARED  NB. normal mapping         
  t=. t,:       O_RDONLY, PROT_READ,               MAP_SHARED  NB. ro mapping
  mtflags=:  t, O_RDWR,   (PROT_WRITE+PROT_READ),  MAP_PRIVATE NB. cow mapping
else.
  CREATE_ALWAYS=: 2
  CREATE_NEW=: 1
  FALSE=: 0
  FILE_BEGIN=: 0
  FILE_END=: 2
  FILE_MAP_COPY=: 1
  FILE_MAP_READ=: 4
  FILE_MAP_WRITE=: 2
  FILE_SHARE_READ=: 1
  FILE_SHARE_WRITE=: 2
  GENERIC_READ=: _2147483648
  GENERIC_WRITE=: 1073741824
  OPEN_ALWAYS=: 4
  OPEN_EXISTING=: 3
  PAGE_READONLY=: 2
  PAGE_READWRITE=: 4
  TRUNCATE_EXISTING=: 5
  NB.                
  t=.           (GENERIC_READ+GENERIC_WRITE), PAGE_READWRITE,  FILE_MAP_WRITE
  t=.       t,: GENERIC_READ,                 PAGE_READONLY,   FILE_MAP_READ
  mtflags=: t,  (GENERIC_READ+GENERIC_WRITE), PAGE_READWRITE,  FILE_MAP_COPY

  CloseHandleR=: 'kernel32 CloseHandle > i x'&(15!:0)
  CreateFileMappingR=: 'kernel32 CreateFileMappingW > x x * i i i *w'&(15!:0)
  CreateFileR=: 'kernel32 CreateFileW > x *w i i * i i x'&(15!:0)
  GetLastError=: 'kernel32 GetLastError > i'&(15!:0)
  FlushViewOfFileR=: 'kernel32 FlushViewOfFile > i * x'&(15!:0)
  MapViewOfFileR=: >@{.@('kernel32 MapViewOfFile * x i i i x'&(15!:0))
  OpenFileMappingR=: 'kernel32 OpenFileMappingW > x i i *w'&(15!:0)
  SetEndOfFile=: 'kernel32 SetEndOfFile > i x'&(15!:0)
  UnmapViewOfFileR=: 'kernel32 UnmapViewOfFile > i *'&(15!:0)
  WriteFile=: 'kernel32 WriteFile i x * i *i *'&(15!:0)
  if. IF64 do.
    GetFileSizeR=: 2 >@{ 'kernel32 GetFileSizeEx i x *x' 15!:0 ;&(,2)
    SetFilePointerR=: 'kernel32 SetFilePointerEx > i x x *x i'&(15!:0)
  else.
    GetFileSizeR=: 'kernel32 GetFileSize > i x *i' 15!:0 ;&(<NULLPTR)
    SetFilePointerR=: 'kernel32 SetFilePointer > i x i *i i'&(15!:0)
  end.
end.

if. _1 = 4!:0<'mappings' do.
  mappings=: i.0 10
end.
empty''
)


