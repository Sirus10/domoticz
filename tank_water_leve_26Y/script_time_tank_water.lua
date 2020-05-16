-- /******************************************
-- # This script aim at reporting tack water level
-- #      using a pressure sensor kelelr Serie 26Y
-- # Site    : https://domotique.web2diz.net/
-- # Detail  : https://domotique.web2diz.net/?p=958
-- #
-- # License : CC BY-SA 4.0
-- #
-- /*******************************************/
commandArray = {}
-- fonction calcule la différence de temps (en secondes) entre maintenant
--et la date passée en paramètre.
function timedifference (s)
  year = string.sub(s, 1, 4)
  month = string.sub(s, 6, 7)
  day = string.sub(s, 9, 10)
  hour = string.sub(s, 12, 13)
  minutes = string.sub(s, 15, 16)
  seconds = string.sub(s, 18, 19)
  t1 = os.time()
  t2 = os.time{year=year, month=month, day=day, hour=hour, min=minutes, sec=seconds} 
  difference = os.difftime (t1, t2)
  return difference
end

-- Fonction qui retourne l'arrondi
function round(num, numDecimalPlaces)
  local mult = 10^(numDecimalPlaces or 0)
  return math.floor(num * mult + 0.5) / mult
end 

-- Si le cpteur 'JardinCuve' à été mis a jour il y a moins de 120s 
-- et que le capteur 'Niveau Eau' a été mis a jour il y a plus de 130s
if ( timedifference(otherdevices_lastupdate['JardinCuve']) < 120 and timedifference(otherdevices_lastupdate['Niveau Eau']) > 130 or true)
then
    val = tonumber(otherdevices_svalues['JardinCuve'])*10; 
	-- debut configuration de la cuve à addapteur à votre cuve
	valMAX=455;	-- valeur recu pour cuve pleine (lecture analogique cuve plaine) 
	valMin=340;	-- valeur recu pour cuve vide	(lecture analogique cuve vide  
	volMAX=220; -- volume pour cuve pleine en L
	-- fin configuration de la cuve à addapteur à votre cuve
	
   if (tonumber(val) > tonumber(valMAX) or val < tonumber(valMin) ) -- uniquement les valeur correcte
   then  
    print('Lecture capteur : '..val.. 'volt  mauvaise lecture' ); 
   else 
	vol= (val-valMin)/(valMAX-valMin)*volMAX; 	-- un peu de math...
	vol = round(vol,2); 						-- arrondi pour affichage
	
	-- pour lisser la courbe on va faire une courbe de tendence 
	-- moyenne sur les deux derniere meusure 
	volPrec=tonumber(otherdevices_svalues['CuveAvg']); 
	volAvg=(vol+volPrec)/2;
	volAvg = round(volAvg,2);
	prtagePein=round(volAvg/volMAX*100,1);  		-- calcul du remplissage en % 
	
	
	 -- this is ok for updating multiple devices see https://www.domoticz.com/forum/viewtopic.php?t=17711#p196832
	commandArray[#commandArray+1] = {['UpdateDevice'] = '5780|1|'..prtagePein}  -- mise a jour du capteur % 'Niveau Eau' qui a pour idx 5780 pour moi
	commandArray[#commandArray+1] = {['UpdateDevice'] = '6620|1|'..vol}			-- mise a jour du capteur Litre 'Cuve' qui a pour idx 6620 pour moi
--	commandArray[#commandArray+1] = {['UpdateDevice'] = '6678|1|'..volAvg}		-- mise a jour du capteur Litre 'Cuve AVG' qui a pour idx 6678 pour moi

	print('Niveau eau meusurée : '..(val)..' |  Cuve pleine à '..prtagePein..'% = '..vol..' L ')   
	print('Niveau eau meusurée : '..(val)..' |  Cuve pleine à '..prtagePein..'% = '..volAvg..' L (AVG)')  
   end 	

end
return commandArray

