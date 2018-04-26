NB. jmf util

symget=: 15!:6 NB. get address of locale entry for name
symset=: 15!:7 NB. set name to address header

NB. must set HADC in same sentence as 15!:8 !!!
allochdr=: 3 : 'r[2 memw (r=.15!:8 y),HADC,1,JINT'

freehdr=: 15!:9 NB. free header

NB. =========================================================
msize=: 3 : 'memr y,HADM,1,JINT'
refcount=: 3 : 'memr y,HADC,1,JINT'

nountype =: 17 b.&16b1fffff  NB. just the noun-type part of y, removing upper flag bits

NB. =========================================================
NB. unsigned (x:) from signed (J integer)
NB. signed (J integer) from unsigned (x:)
MAXINTU=: 2 ^ IF64{32 64x
MAXINTS=: <: 2 ^ IF64{31 63x
ufs=: + MAXINTU * 0 > ]
sfu=: _1 x: ] - MAXINTU * MAXINTS < ]

NB. =========================================================
NB. findkey
NB. Syntax: {row}=. {search string} FindKey {n x m table where column 0 = key}
NB.   - Returns a vector of row numbers whose column 0 value matches the search string
NB. Example:
NB.   Table=.('One';'Two';'Three';'Four'),.('uno';'dos';'tres';'quatro'),.('un';'deux';'trois';'quatre')
NB.   'Four' findkey Table					NB. Returns row 3
findkey=: 4 : 'I. (<x) = {."1 y'

NB. =========================================================
free=: 3 : 0
'fh mh fad'=. y
if. IFUNIX do.
  if. fad do. c_munmap (<fad);mh end.
  if. fh~:_1 do. c_close fh end.
else.
  if. fad do. UnmapViewOfFileR <<fad end.
  if. mh do. CloseHandleR mh end.
  if. fh~:_1 do. CloseHandleR fh end.
end.
)

NB. =========================================================
fullname=: 3 : 0
t=. y-.' '
t,('_'~:{:t)#'_base_'
)

NB. =========================================================
mbxcheck=: 3 : 0
x=. 15!:12 y                  NB. 3 col integer matrix
b=. 0={:"1 x                  NB. selects code 0
'a s c'=. |: (-.b)#x          NB. address (sorted), size, code
'u n z'=. ,b#x                NB. address 0, length, junk
z=. *./ c e. 1 2              NB. code must be 1 or 2
z=. z, (-:<.) 2^.s            NB. sizes are powers of 2
z=. z, (}.a)-:}:a+s           NB. blocks are contiguous
z=. z, u = {.a                NB. first block begins at address 0
z=. z, ({:a+s) <: u+n         NB. last block is within bounds
z=. z, (-: <.) 64 %~ +/s      NB. total block sizes is multiple of 64
z=. z, (+/s) = <.&.(%&64) n   NB. total block sizes matches rounded total size
z=. z, *./ 0 = 8|a            NB. addresses are doubleword aligned
)

NB. =========================================================
NB. set shape of mapped noun
settypeshape=: 3 : 0
'name type shape'=: y
type =: nountype type
rank=. #shape
sad=. symget <fullname name
'bad name' assert sad
had=. 1{s=. memr sad,0 4,JINT
'flag msize'=. memr had,HADFLAG,2,JINT
'not mapped and writeable' assert 2=flag
size=. (JTYPES i.type){JSIZES
ts=. size**/shape
'msize too small' assert ts<:msize
type memw had,HADT,1,JINT
((*/shape),rank,shape) memw had,HADN,(2+rank),JINT
i.0 0
)

NB. =========================================================
NB. 1 if jmf header is: big enough, offset=HS, msize=ts-HS, valid JTYPE
validate=: 3 : 0
'ts had'=. y
if. ts>:HS do.
  d=. memr had,0 4,JINT
  *./((HS,ts-HS)=0 2{d),1 2 4 8 16 32 131072 262144 65536 e.~ nountype 3{d
else. 0 end.
)
