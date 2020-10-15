// !COO! pagal !LukniS! iðmislà ;)
new Objektai;
stock COO_CreateObject(modelid, Float:X, Float:Y, Float:Z, Float:rX, Float:rY, Float:rZ, Float:DrawDistance=0.0)
{
	Objektai++;
	return CreateObject(modelid, X, Y, Z, rX, rY, rZ, DrawDistance);
}
stock CountOriginalObjects()
{
   return Objektai;
}
#define CreateObject COO_CreateObject
