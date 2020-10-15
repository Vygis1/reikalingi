#include <a_samp>
#include <sscanf2>
#pragma dynamic                 1000000
#define MaxObjRemove	500
enum objinfo
{
	modelid_,
	Float:x_,
	Float:y_,
	Float:z_,
	Float:radius_
}
new rObj[MaxObjRemove][objinfo];


forward Convert(file[]);
public Convert(file[])
{
	if (!fexist(file)) return print("file not found");
	new File:openfile = fopen(file);
	new string[40000], string2[40000], playerid, objcount;
	while(fread(openfile, string))
	{
		for(new idk = 0; idk < sizeof(rObj); idk++)
		{
			if(!sscanf(string, "p<\">'removeWorldObject''radius='f'model='d'posX='f'posY='f'posZ='f",rObj[idk][radius_],rObj[idk][modelid_],rObj[idk][x_],rObj[idk][y_],rObj[idk][z_]))
			{
				objcount++;
				RemoveBuildingForPlayer(playerid, rObj[idk][modelid_], rObj[idk][x_], rObj[idk][y_], rObj[idk][z_], rObj[idk][radius_]);
				new File:newfile = fopen("Converted.pwn",io_write);
				format(string,sizeof(string),"RemoveBuildingForPlayer(playerid, %d, %f, %f, %f, %f); \r\n",rObj[idk][modelid_], rObj[idk][x_], rObj[idk][y_], rObj[idk][z_], rObj[idk][radius_]);
				strcat(string," \n");
				strcat(string2,string);
				fwrite(newfile,string2);
				fclose(newfile);
			}
		}
	
	}
	fclose(openfile);
	printf("%d objects were converted from '%s' to Converted.pwn (Saved in Scriptfiles folder)",objcount, file);
	return objcount;
}





