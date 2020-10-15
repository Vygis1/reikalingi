/*

		iScreenFader 1.6
		pabaigta 2012m. Liepos 5d. 12:11

		Autorius: InstincT
		Keisti kreditus draudþiama! Pakeitæs kreditus autoriumi netapsi!

		funkcijos
			FadeScreenForPlayer( playerid, mode, color = 0x0FF, steps = -1 )
			playerid - þaidëjo ID
			mode - uþtemdymo rëþimas. Jø yra du tipai:
				FADE_IN - uþtemdyti(po truputá padaryti ekranà juodà)
				FADE_OUT - atitemdyti(po truputá padaryti ekranà matomà)
			**color - spalva
			**steps - skaièius, kokia reikðme bus maþinamas fsSteps kintamasis

			FadePlayerPos( playerid, color = 0x0FF, Float:fsPosX, Float:fsPosY, Float:fsPosZ, Float:fsPosA = -1.0, fsInt = -1, fsVW = -1, fsClearAnims = false, fsCamera = false, steps = -1 )
			playerid - þaidëjo ID
			**color - spalva
			fsPosX - koordinatë X
			fsPosY - koordinatë Y
			fsPosZ - koordinatë Z
			**fsPosA - pasisukimo laipsniai
			**fsInt - interioras
			**fsVW - virtual worldas
			**fsClearAnims - ar uþtamsinus ekranà ávykdyti funkcijà ClearAnimations
			**fsCamera - ar uþtamsinus ekranà ávykdyti funkcijà SetCameraBehindPlayer
			**steps - skaièius, kokia reikðme bus maþinamas fsSteps kintamasis

			FadeSkinForPlayer( playerid, skinID, color = 0x0FF steps = -1 )
			playerid - þaidëjo ID
			skinID - skino ID
			**color - spalva
			**steps - skaièius, kokia reikðme bus maþinamas fsSteps kintamasis

			iScreenFader_Kokybe( id );
			id - kokybës ID. Galimi du variantai:
				FADE_KOKYBE_GERA - gera kokybë, timer'io intervalas yra 20, fsSteps kintamojo maþinimas 4
				FADE_KOKYBE_BLOGA - vidutiniðka kokybë, timer'io intervalas 100, fsSteps kintamojo maþinimas 20

			** - PARAMETRAS NEBÛTINAS! Norint já praleisti funkcijos kvietime, vietoj parametro raðykit _

		callbackai
			OnFadeComplete( playerid, mode, color )
				playerid - þaidëjo ID
				mode - uþtemdymo rëþimas
				color - uþtemdyta/atitemdyta spalva

		changelogas
			2012m. Birþelio 12d.:
				- iðleista
			2012m. Birþelio 13d.:
				- padaryti praneðimai bei vykdymo nutraukimai, kuriø dëka bus iðvengiamas netaisyklingas funkcijø naudojimas,
				- naudojami PlayerTextDraw'ai vietoje globaliø TextDraw'ø,
				- viskas turëtø veikti dvigubai greièiau, pakeistas timer'io intervalas ið 5 á 10, taip pat kintamasis fsSteps maþinamas dviem vienetais
				- naujos funkcijos:
						FadePlayerPos, FadePlayerSkin
			2012m. Birþelio 14d.:
				- pridëta galimybë kontroliuoti spalvas visose funkcijose. Parametras nëra bûtinas, spalva pagal nutylëjimà - juoda(0x0FF).
				- OnFadeComplete callback'ui pridëtas spalvos parametras
				- viskas turëtø veikti dar dvigubai greièiau, pakeistas timer'io intervalas ið 5 á 10, taip pat kintamasis fsSteps maþinamas keturiais vienetais
				- funkcijai FadePlayerPos pridëta galimybë uþtamsinus ekranà ávykdyti funkcijà SetCameraBehindPlayer bei ClearAnimations
				- iðtaisyta klaida, dël kurios galëjo neatitemdyti ekrano.
				- iðtaisyta klaida, dël kurios informaciniuose praneðimuose konsolëje nerodydavo þaidëjo ID
				- naujos funkcijos:
						iScreenFader_Kokybe - pakeisti uþtemdymo/atitemdymo kokybæ.
			2012m. Birþelio 20d.:
				- iðtaisyta klaida, dël kurios panaudojus FadePlayerPos funkcijà, o paskui kità uþtemdymo funkcijà vël þaidëjo pozicija buvo nustatoma á prieð tai naudotosios funkcijos FadePlayerPos nustatytà pozicijà.
			2012m. Birþelio 21d.:
				- iðtaisyta klaida, dël kurios pirmà kartà po serverio ájungimo panaudojus ne FadePlayerPos funkcijà, galëjo uþtamsinus ekranà þaidëjus nukelti á neteisingà pozicijà. Tas pats ir su interior'u bei virtual world'u.
			2012m. Birþelio 23d.:
				- naudojamas vienas vienintelis globalus TextDraw'as, vietoje kiekvienam þaidëjui kuriamo atskirai PlayerTextDraw'o.
			2012m. Liepos 5d.:
				- pridëta galimybë visose tamsinimo/atitamsinimo funkcijose kontroliuoti, kokiu skaièiu bus maþinamas fsSteps kintamasis.
				- OnFadeComplete callback'ui pridëtas parametras steps, nurodantis kokiu skaièiu þaidëjui buvo maþinamas kintamasis fsSteps.
*/


#define FADE_IN 1
#define FADE_OUT 2


forward OnFadeComplete( playerid, mode, color, steps );


enum fadeScreenEnumas
{
	fsTimer,
	fsSteps,
	fsMode,
	fsColor,
	fsMazinimasSteps,
	Float:fsPos[ 4 ],
	fsInterior,
	fsVirtualWorld,
	fsSkin,
	fsClearAnimations,
	fsCameraBehindPlayer
}

#define FADE_KOKYBE_GERA 1
#define FADE_KOKYBE_BLOGA 2

new
	fadeScreen[ MAX_PLAYERS ][ fadeScreenEnumas ],
	Text:fsTextDraw,
	bool:fsTD_sukurtas,
	fadeKokybe_intervalas = 20,
	fadeKokybe_mazinimas = 4
;

stock iScreenFader_Kokybe( id )
{
	if( id != FADE_KOKYBE_GERA && id != FADE_KOKYBE_BLOGA ) return print( "KLAIDA iScreenFader naudojime! iScreenFader_Kokybe funkcijoje naudjama netinkama reikðmë." );
	if( id == FADE_KOKYBE_GERA )
	{
		fadeKokybe_intervalas = 20;
		fadeKokybe_mazinimas = 4;
	}
	else
	{
		fadeKokybe_intervalas = 100;
		fadeKokybe_mazinimas = 20;
	}
	return 1;
}

stock FadeScreenForPlayer( playerid, mode, color = 0x0FF, steps = -1 )
{
	if( mode != FADE_IN && mode != FADE_OUT ) return printf( "KLAIDA iScreenFader naudojime! FadeScreenForPlayer þaidëjui %d mode buvo netinkamas.", playerid );
	if( fadeScreen[ playerid ][ fsSteps ] > 0 ) return printf( "KLAIDA iScreenFader naudojime! FadeScreenForPlayer funkcijoje þaidëjas %d jau naudoja ekrano tamsinimà.", playerid );
	if( steps == 0 ) return printf( "KLAIDA iScreenFader naudojime! FadeScreenForPlayer funkcijoje þaidëjui %d parametras steps buvo 0!", playerid );
	fadeScreen[ playerid ][ fsSteps ] = 255;
	fadeScreen[ playerid ][ fsMazinimasSteps ] = ( steps == -1 ) ? ( fadeKokybe_mazinimas ) : ( steps );
	fadeScreen[ playerid ][ fsMode ] = mode;
	fadeScreen[ playerid ][ fsColor ] = color;
	fadeScreen[ playerid ][ fsTimer ] = SetTimerEx( "FadeScreen", fadeKokybe_intervalas, true, "d", playerid );
	return 1;
}
/*
stock FadePlayerPos( playerid, color = 0x0FF, Float:fsPosX, Float:fsPosY, Float:fsPosZ, Float:fsPosA = -1.0, fsInt = -1, fsVW = -1, fsClearAnims = true, fsCamera = false, steps = -1 )
{
	if( fadeScreen[ playerid ][ fsSteps ] > 0 ) return printf( "KLAIDA iScreenFader naudojime! FadePlayerPos funkcijoje þaidëjas %d jau naudoja ekrano tamsinimà.", playerid );
	if( steps == 0 ) return printf( "KLAIDA iScreenFader naudojime! FadeScreenForPlayer funkcijoje þaidëjui %d parametras steps buvo 0!", playerid );
	fadeScreen[ playerid ][ fsSteps ] = 255;
	fadeScreen[ playerid ][ fsMazinimasSteps ] = ( steps == -1 ) ? ( fadeKokybe_mazinimas ) : ( steps );
	fadeScreen[ playerid ][ fsMode ] = FADE_IN;
	fadeScreen[ playerid ][ fsColor ] = color;
	fadeScreen[ playerid ][ fsPos ][ 0 ] = fsPosX + 1.0;
	fadeScreen[ playerid ][ fsPos ][ 1 ] = fsPosY + 1.0;
	fadeScreen[ playerid ][ fsPos ][ 2 ] = fsPosZ + 1.0;
	fadeScreen[ playerid ][ fsPos ][ 3 ] = fsPosA + 1.0;
	fadeScreen[ playerid ][ fsInterior ] = fsInt + 1;
	fadeScreen[ playerid ][ fsVirtualWorld ] = fsVW + 1;
	fadeScreen[ playerid ][ fsClearAnimations ] = fsClearAnims;
	fadeScreen[ playerid ][ fsCameraBehindPlayer ] = fsCamera;
	fadeScreen[ playerid ][ fsTimer ] = SetTimerEx( "FadeScreen", fadeKokybe_intervalas, true, "d", playerid );
	return 1;
}

stock FadePlayerSkin( playerid, skinID, color = 0x0FF, steps = -1 )
{
	if( fadeScreen[ playerid ][ fsSteps ] > 0 ) return printf( "KLAIDA iScreenFader naudojime! FadePlayerSkin funkcijoje þaidëjas %d jau naudoja ekrano tamsinimà.", playerid );
	if( steps == 0 ) return printf( "KLAIDA iScreenFader naudojime! FadeScreenForPlayer funkcijoje þaidëjui %d parametras steps buvo 0!", playerid );
	fadeScreen[ playerid ][ fsSteps ] = 255;
	fadeScreen[ playerid ][ fsMazinimasSteps ] = ( steps == -1 ) ? ( fadeKokybe_mazinimas ) : ( steps );
	fadeScreen[ playerid ][ fsMode ] = FADE_IN;
	fadeScreen[ playerid ][ fsColor ] = color;
	fadeScreen[ playerid ][ fsSkin ] = skinID + 1;
	fadeScreen[ playerid ][ fsTimer ] = SetTimerEx( "FadeScreen", fadeKokybe_intervalas, true, "d", playerid );
	return 1;
}
*/

forward FadeScreen( playerid );
public FadeScreen( playerid )
{
	if( !fsTD_sukurtas )
	{
		fsTextDraw = TextDrawCreate( -159.000000, -288.000000, "iScreenFader by InstincT" );
		TextDrawBackgroundColor( fsTextDraw, 255 );
		TextDrawFont( fsTextDraw, 0 );
		TextDrawLetterSize( fsTextDraw, 0.270000, 88.999687 );
		TextDrawColor( fsTextDraw, -1 );
		TextDrawSetOutline( fsTextDraw, 0 );
		TextDrawSetProportional( fsTextDraw, 1 );
		TextDrawSetShadow( fsTextDraw, 1 );
		TextDrawUseBox( fsTextDraw, 1 );
		TextDrawBoxColor( fsTextDraw, 255 );
		TextDrawTextSize( fsTextDraw, 848.000000, 2.000000 );
		fsTD_sukurtas = true;
	}
	TextDrawBoxColor( fsTextDraw, GetFadeColor( fadeScreen[ playerid ][ fsSteps ], fadeScreen[ playerid ][ fsMode ], fadeScreen[ playerid ][ fsColor ] ) );
	TextDrawShowForPlayer( playerid, fsTextDraw );
	fadeScreen[ playerid ][ fsSteps ] -= fadeScreen[ playerid ][ fsMazinimasSteps ];
	if( fadeScreen[ playerid ][ fsSteps ] <= 0 )
	{
		KillTimer( fadeScreen[ playerid ][ fsTimer ] );
		if( fadeScreen[ playerid ][ fsMode ] == FADE_OUT )
		{
			TextDrawHideForPlayer( playerid, fsTextDraw );
		}
		else
		{
			if( fadeScreen[ playerid ][ fsPos ][ 0 ] != 0.0 && fadeScreen[ playerid ][ fsPos ][ 1 ] != 0.0 && fadeScreen[ playerid ][ fsPos ][ 2 ] != 0.0 )
			{
				SetPlayerPos( playerid, fadeScreen[ playerid ][ fsPos ][ 0 ] - 1.0, fadeScreen[ playerid ][ fsPos ][ 1 ] - 1.0, fadeScreen[ playerid ][ fsPos ][ 2 ] - 1.0 );
				fadeScreen[ playerid ][ fsPos ][ 0 ] = 0.0;
				fadeScreen[ playerid ][ fsPos ][ 1 ] = 0.0;
				fadeScreen[ playerid ][ fsPos ][ 2 ] = 0.0;

				if( fadeScreen[ playerid ][ fsPos ][ 3 ] != 0.0 )
				{
					SetPlayerFacingAngle( playerid, fadeScreen[ playerid ][ fsPos ][ 3 ] - 1.0 );
					fadeScreen[ playerid ][ fsPos ][ 3 ] = 0.0;
				}
				if( fadeScreen[ playerid ][ fsInterior ] != 0 )
				{
					SetPlayerInterior( playerid, fadeScreen[ playerid ][ fsInterior ] - 1 );
					fadeScreen[ playerid ][ fsInterior ] = 0;
				}
				if( fadeScreen[ playerid ][ fsVirtualWorld ] != 0 )
				{
					SetPlayerVirtualWorld( playerid, fadeScreen[ playerid ][ fsVirtualWorld ] - 1 );
					fadeScreen[ playerid ][ fsVirtualWorld ] = 0;
				}
				FadeScreenForPlayer( playerid, FADE_OUT, fadeScreen[ playerid ][ fsColor ], fadeScreen[ playerid ][ fsMazinimasSteps ] );
			}
			if( fadeScreen[ playerid ][ fsSkin ] != 0 )
			{
				SetPlayerSkin( playerid, fadeScreen[ playerid ][ fsSkin ] - 1 );
				fadeScreen[ playerid ][ fsSkin ] = 0;
				FadeScreenForPlayer( playerid, FADE_OUT, fadeScreen[ playerid ][ fsColor ], fadeScreen[ playerid ][ fsMazinimasSteps ] );
			}
			if( fadeScreen[ playerid ][ fsClearAnimations ] )
			{
				fadeScreen[ playerid ][ fsClearAnimations ] = false;
				ClearAnimations( playerid );
			}
			if( fadeScreen[ playerid ][ fsCameraBehindPlayer ] )
			{
				fadeScreen[ playerid ][ fsCameraBehindPlayer ] = false;
				SetCameraBehindPlayer( playerid );
			}
		}
		CallRemoteFunction( "OnFadeComplete", "ddxd", playerid, fadeScreen[ playerid ][ fsMode ], fadeScreen[ playerid ][ fsColor ], fadeScreen[ playerid ][ fsMazinimasSteps ] );
		return 1;
	}
	return 1;
}

stock GetFadeColor( steps, mode, color )
{
	new
		alpha,
		rgb[ 3 ],
		hex
	;
	if( mode == FADE_IN ) alpha = 255 - steps;
	else alpha = 255 - ( 255 - steps );

	// aèiû 0x5A656578(a.k.a. Zeex)!
	rgb[ 0 ] = ( color & 0xFF000000 ) >>> 24;
	rgb[ 1 ] = ( color & 0x00FF0000 ) >>> 16;
	rgb[ 2 ] = ( color & 0x0000FF00 ) >>> 8;

	hex |= ( rgb[ 0 ] & 0xFF ) << 24;
	hex |= ( rgb[ 1 ] & 0xFF ) << 16;
	hex |= ( rgb[ 2 ] & 0xFF ) << 8;
	hex |= ( alpha & 0xFF );
	return hex;
}