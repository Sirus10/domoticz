commandArray = {}
-- fonction calcule la différence de temps (en secondes) entre maintenant
-- et la date passée en paramètre.
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


-- Si le cpteur 'Niveau eau temp' à été mis a jour il y a moins de 120s 
-- et que le capteur 'Niveau Eau' a été mis a jour il y a plus de 130s
if ( timedifference(otherdevices_lastupdate['Niveau eau temp']) < 120 and timedifference(otherdevices_lastupdate['Niveau Eau']) > 130)
then
   val = otherdevices_svalues['Niveau eau temp'];
   -- debut configuration de la cuve à addapteur à votre cuve
	hMax=86;	-- hauteur totale
	vTotal=220;	-- volume total
	-- fin configuration de la cuve à addapteur à votre cuve
	hEau=hMax-val; -- calcul de la hauteur d'eau
	prtagePein=round(hEau/hMax*100,2);  	-- calcul du remplissage en % 
	vPein=round(prtagePein/100*vTotal,1)	-- calcul du remplissage en litre 
   commandArray['UpdateDevice']='5780|0|'..prtagePein;	-- mise a jour du capteur  'Niveau Eau' qui a pour idx 5780 pour moi
   print('Niveau eau distance meusurée : '..val..'cm | Hauteur d\'eau  '..hEau..'cm | Cuve pleine à '..prtagePein..'% = '..vPein..' L ')
end
return commandArray

