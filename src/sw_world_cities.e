note
	description: "[
		Every city Natural Earth 110m knows (243 populated
		places, public domain), generated into data-only source by
		tools/gen_world_cities.py - DO NOT EDIT BY HAND. Name,
		country, lat/lon and peak population per city, biggest
		first, parsed once and shared.
	]"

class
	SW_WORLD_CITIES

feature -- Access

	cities: ARRAYED_LIST [TUPLE [name, country: STRING_32; lat, lon: REAL_64; population: INTEGER]]
			-- All places, biggest population first. Parsed once.
		once
			create Result.make (243)
			parse_block (data_1, Result)
		ensure
			many: Result.count >= 200
		end

feature {NONE} -- Parsing

	parse_block (a_data: STRING; a_acc: ARRAYED_LIST [TUPLE [name, country: STRING_32; lat, lon: REAL_64; population: INTEGER]])
			-- Records end at ';', fields split on '~'; line breaks
			-- fall only BETWEEN records by generator law, so stray
			-- whitespace is trimmed at field edges only.
		local
			i, n, f: INTEGER
			c: CHARACTER
			fields: ARRAY [STRING]
			tok: STRING
		do
			create fields.make_filled (create {STRING}.make_empty, 1, 5)
			create tok.make (24)
			f := 1
			n := a_data.count
			from
				i := 1
			until
				i > n
			loop
				c := a_data.item (i)
				if c = ';' then
					fields [f] := tok.twin
					if f = 5 then
						a_acc.extend ([
							fields [1].to_string_32,
							fields [2].to_string_32,
							fields [3].to_double,
							fields [4].to_double,
							fields [5].to_integer])
					end
					tok.wipe_out
					f := 1
				elseif c = '~' then
					fields [f] := tok.twin
					tok.wipe_out
					if f < 5 then
						f := f + 1
					end
				elseif c = '%N' or c = '%T' or c = '%R' then
					-- between-records air only, by generator law
				else
					tok.extend (c)
				end
				i := i + 1
			end
		end

feature {NONE} -- Generated data (Natural Earth 110m, public domain)

	data_1: STRING = "[
		Tokyo~Japan~35.69~139.75~35676000;New York~United States of America~40.72~-74.0~19040000;
		Mexico City~Mexico~19.44~-99.13~19028000;Mumbai~India~19.07~72.88~18978000;
		Sao Paulo~Brazil~-23.56~-46.63~18845000;Shanghai~China~31.22~121.43~14987000;
		Kolkata~India~22.57~88.37~14787000;Dhaka~Bangladesh~23.73~90.41~12797394;
		Buenos Aires~Argentina~-34.61~-58.43~12795000;
		Los Angeles~United States of America~34.05~-118.23~12500000;Cairo~Egypt~30.05~31.25~11893000;
		Rio de Janeiro~Brazil~-22.91~-43.21~11748000;Osaka~Japan~34.69~135.5~11294000;
		Beijing~China~39.9~116.39~11106000;Manila~Philippines~14.61~120.98~11100000;
		Moscow~Russia~55.75~37.61~10452000;Istanbul~Turkey~41.02~28.97~10061000;
		Paris~France~48.86~2.35~9904000;Seoul~South Korea~37.57~127.0~9796000;
		Lagos~Nigeria~6.45~3.39~9466000;Jakarta~Indonesia~-6.17~106.83~9125000;
		Chicago~United States of America~41.85~-87.64~8990000;London~United Kingdom~51.5~-0.12~8567000;
		Lima~Peru~-12.05~-77.05~8012000;Tehran~Iran~35.67~51.42~7873000;
		Kinshasa~Congo (Kinshasa)~-4.33~15.31~7843000;Bogota~Colombia~4.6~-74.09~7772000;
		Hong Kong~Hong Kong S.A.R.~22.31~114.18~7206000;Taipei~Taiwan~25.04~121.57~6900273;
		Bengaluru~India~12.97~77.56~6787000;Bangkok~Thailand~13.75~100.51~6704000;
		Santiago~Chile~-33.44~-70.65~5720000;Miami~United States of America~25.79~-80.23~5585000;
		Madrid~Spain~40.4~-3.69~5567000;Toronto~Canada~43.66~-79.39~5213000;
		Singapore~Singapore~1.29~103.85~5183700;Luanda~Angola~-8.84~13.23~5172900;
		Baghdad~Iraq~33.34~44.39~5054000;Khartoum~Sudan~15.59~32.53~4754000;
		Sydney~Australia~-33.87~151.21~4630000;Atlanta~United States of America~33.74~-84.37~4506000;
		Riyadh~Saudi Arabia~24.63~46.72~4465000;Houston~United States of America~29.74~-95.35~4459000;
		Hanoi~Vietnam~21.04~105.85~4378000;
		Washington, D.C.~United States of America~38.9~-77.01~4338000;
		Melbourne~Australia~-37.82~144.97~4170000;Chengdu~China~30.67~104.07~4123000;
		Rangoon~Myanmar~16.79~96.16~4088000;Abidjan~Ivory Coast~5.32~-4.02~3802000;
		Brasilia~Brazil~-15.78~-47.92~3716996;Ankara~Turkey~39.93~32.86~3716000;
		Monterrey~Mexico~25.67~-100.33~3712000;Urumqi~China~43.81~87.57~3575000;
		San Francisco~United States of America~37.78~-122.4~3450000;
		Johannesburg~South Africa~-26.17~28.03~3435000;Berlin~Germany~52.52~13.4~3406000;
		Algiers~Algeria~36.77~3.05~3354000;Rome~Italy~41.9~12.48~3339000;
		Pyongyang~North Korea~39.02~125.75~3300000;Kabul~Afghanistan~34.52~69.18~3277000;
		Athens~Greece~37.99~23.73~3242000;Cape Town~South Africa~-33.92~18.43~3215000;
		Casablanca~Morocco~33.6~-7.62~3181000;Tel Aviv-Yafo~Israel~32.08~34.77~3112000;
		Addis Ababa~Ethiopia~9.04~38.7~3100000;Nairobi~Kenya~-1.28~36.81~3010000;
		Caracas~Venezuela~10.5~-66.92~2985000;Dar es Salaam~Tanzania~-6.8~39.27~2930000;
		Lisbon~Portugal~38.72~-9.15~2812000;Kiev~Ukraine~50.44~30.51~2709000;
		Dakar~Senegal~14.72~-17.48~2604000;Damascus~Syria~33.5~36.3~2466000;
		Tunis~Tunisia~36.8~10.18~2412500;Vienna~Austria~48.2~16.36~2400000;
		Vancouver~Canada~49.28~-123.12~2313328;Denver~United States of America~39.74~-104.99~2313000;
		Tripoli~Libya~32.89~13.18~2189000;Tashkent~Uzbekistan~41.3~69.27~2184000;
		Havana~Cuba~23.13~-82.37~2174000;Santo Domingo~Dominican Republic~18.47~-69.93~2154000;
		Baku~Azerbaijan~40.4~49.86~2122300;Accra~Ghana~5.55~-0.22~2121000;
		Kuwait City~Kuwait~29.37~47.98~2063000;Sanaa~Yemen~15.36~44.2~2008000;
		Port-au-Prince~Haiti~18.54~-72.34~1998000;Bucharest~Romania~44.44~26.1~1942000;
		Asuncion~Paraguay~-25.29~-57.63~1870000;Beirut~Lebanon~33.87~35.51~1846000;
		Kyoto~Japan~35.03~135.75~1805000;Minsk~Belarus~53.9~27.56~1805000;
		Brussels~Belgium~50.84~4.33~1743000;Warsaw~Poland~52.23~21.01~1707000;
		Rabat~Morocco~34.03~-6.84~1705000;Quito~Ecuador~-0.21~-78.5~1701000;
		Antananarivo~Madagascar~-18.91~47.51~1697000;Budapest~Hungary~47.5~19.08~1679000;
		Yaounde~Cameroon~3.87~11.51~1611000;La Paz~Bolivia~-16.5~-68.15~1590000;
		Abuja~Nigeria~9.05~7.49~1576000;Harare~Zimbabwe~-17.82~31.04~1572000;
		Montevideo~Uruguay~-34.91~-56.19~1513000;Bamako~Mali~12.65~-8.0~1494000;
		Conakry~Guinea~9.53~-13.68~1494000;Phnom Penh~Cambodia~11.55~104.91~1466000;
		Lome~Togo~6.13~1.22~1452000;Doha~Qatar~25.29~51.53~1450000;
		Kuala Lumpur~Malaysia~3.14~101.69~1448000;Maputo~Mozambique~-25.95~32.59~1446000;
		San Salvador~El Salvador~13.7~-89.22~1433000;Kampala~Uganda~0.32~32.58~1420000;
		The Hague~Netherlands~52.08~4.27~1406000;Dubai~United Arab Emirates~25.21~55.29~1379000;
		Auckland~New Zealand~-36.85~174.76~1377200;Brazzaville~Congo (Brazzaville)~-4.26~15.28~1355000;
		Pretoria~South Africa~-25.7~28.23~1338000;Lusaka~Zambia~-15.41~28.28~1328000;
		San Jose~Costa Rica~9.93~-84.08~1284000;Panama City~Panama~8.97~-79.53~1281000;
		Stockholm~Sweden~59.32~18.07~1264000;Geneva~Switzerland~46.21~6.14~1240000;
		Sofia~Bulgaria~42.69~23.31~1185000;Prague~Czechia~50.09~14.42~1162000;
		Ouagadougou~Burkina Faso~12.37~-1.53~1149000;Ottawa~Canada~45.42~-75.7~1145000;
		Helsinki~Finland~60.16~24.93~1115000;Yerevan~Armenia~40.18~44.51~1102000;
		Mogadishu~Somalia~2.07~45.36~1100000;Tbilisi~Georgia~41.73~44.79~1100000;
		Belgrade~Serbia~44.82~20.47~1099000;Dushanbe~Tajikistan~38.56~68.77~1086244;
		Kobenhavn~Denmark~55.68~12.56~1085000;Amman~Jordan~31.95~35.93~1060000;
		Dublin~Ireland~53.35~-6.26~1059000;Monrovia~Liberia~6.31~-10.8~1041000;
		Amsterdam~Netherlands~52.35~4.91~1031000;Jerusalem~Israel~31.78~35.21~1029300;
		Guatemala~Guatemala~14.62~-90.53~1024000;Ndjamena~Chad~12.12~15.05~989000;
		Tegucigalpa~Honduras~14.1~-87.22~946000;Kingston~Jamaica~17.98~-76.77~937700;
		Naypyidaw~Myanmar~19.77~96.12~930000;Djibouti~Djibouti~11.6~43.15~923000;
		Managua~Nicaragua~12.15~-86.27~920000;Niamey~Niger~13.52~2.11~915000;
		Tirana~Albania~41.33~19.82~895350;Kathmandu~Nepal~27.72~85.31~895000;
		Ulaanbaatar~Mongolia~47.92~106.91~885000;Kigali~Rwanda~-1.95~30.06~860000;
		Valparaiso~Chile~-33.05~-71.62~854000;Bishkek~Kyrgyzstan~42.88~74.58~837000;
		Oslo~Norway~59.92~10.75~835000;Bangui~Central African Republic~4.37~18.56~831925;
		Freetown~Sierra Leone~8.47~-13.24~827000;Islamabad~Pakistan~33.69~73.08~780000;
		Cotonou~Benin~6.36~2.4~762000;Vientiane~Laos~17.97~102.6~754000;Riga~Latvia~56.95~24.1~742572;
		Nouakchott~Mauritania~18.09~-15.98~742144;Muscat~Oman~23.59~58.38~734697;
		Ashgabat~Turkmenistan~37.95~58.38~727700;Zagreb~Croatia~45.8~16.0~722526;
		Sarajevo~Bosnia and Herzegovina~43.85~18.38~696731;Chisinau~Moldova~47.01~28.86~688134;
		Lilongwe~Malawi~-13.98~33.78~646750;Asmara~Eritrea~15.33~38.93~620802;
		Abu Dhabi~United Arab Emirates~24.47~54.37~603492;Port Louis~Mauritius~-20.17~57.5~595491;
		Libreville~Gabon~0.39~9.46~578156;Manama~Bahrain~26.24~50.58~563920;
		Vilnius~Lithuania~54.68~25.32~542366;Skopje~North Macedonia~42.0~21.43~494087;
		Hargeysa~Somaliland~9.56~44.07~477876;Pristina~Kosovo~42.67~21.17~465186;
		Bloemfontein~South Africa~-29.12~26.23~463064;Baguio City~Philippines~16.43~120.57~447824;
		Bratislava~Slovakia~48.15~17.12~423737;Bissau~Guinea Bissau~11.87~-15.6~403339;
		Tallinn~Estonia~59.43~24.73~394024;Wellington~New Zealand~-41.29~174.78~393400;
		Valletta~Malta~35.9~14.51~368250;Maseru~Lesotho~-29.32~27.48~361324;
		Astana~Kazakhstan~51.18~71.43~345604;Bujumbura~Burundi~-3.38~29.36~331700;
		Canberra~Australia~-35.28~149.13~327700;New Delhi~India~28.6~77.2~317797;
		Ljubljana~Slovenia~46.06~14.51~314807;Porto-Novo~Benin~6.48~2.62~300000;
		Bandar Seri Begawan~Brunei~4.88~114.93~296500;
		Port-of-Spain~Trinidad and Tobago~10.65~-61.52~294934;
		Port Moresby~Papua New Guinea~-9.46~147.19~283733;Bern~Switzerland~46.92~7.47~275329;
		Windhoek~Namibia~-22.57~17.08~268132;Georgetown~Guyana~6.8~-58.17~264350;
		Paramaribo~Suriname~5.84~-55.17~254169;Dili~East Timor~-8.56~125.58~234331;
		Nassau~The Bahamas~25.08~-77.35~227940;Sucre~Bolivia~-19.04~-65.26~224838;
		Nicosia~Cyprus~35.17~33.37~224300;Dodoma~Tanzania~-6.18~35.75~218269;
		Colombo~Sri Lanka~6.93~79.86~217000;Gaborone~Botswana~-24.65~25.91~208411;
		Yamoussoukro~Ivory Coast~6.82~-5.28~206499;Bridgetown~Barbados~13.1~-59.62~191152;
		Laayoune~Morocco~27.15~-13.2~188084;Suva~Fiji~-18.13~178.44~175399;
		Reykjavik~Iceland~64.14~-21.94~166212;Malabo~Equatorial Guinea~3.75~8.78~155963;
		Podgorica~Montenegro~42.47~19.27~145850;Moroni~Comoros~-11.7~43.24~128698;
		Sri Jawewardenepura Kotte~Sri Lanka~6.9~79.95~115826;Praia~Cape Verde~14.92~-23.52~113364;
		Male~Maldives~4.17~73.51~112927;Juba~South Sudan~4.83~31.58~111975;
		Luxembourg~Luxembourg~49.61~6.13~107260;Thimphu~Bhutan~27.47~89.64~98676;
		Mbabane~eSwatini~-26.32~31.13~90138;Sao Tome~Sao Tome and Principe~0.34~6.73~88219;
		Honiara~Solomon Islands~-9.44~159.95~76328;Putrajaya~Malaysia~2.93~101.7~67964;
		Apia~Samoa~-13.84~-171.77~61916;Andorra~Andorra~42.51~1.53~53998;
		Kingstown~Saint Vincent and the Grenadines~13.16~-61.22~49485;
		Port Vila~Vanuatu~-17.73~168.32~44040;Banjul~The Gambia~13.45~-16.59~43094;
		Nukualofa~Tonga~-21.14~-175.22~42620;Castries~Saint Lucia~14.01~-60.99~37963;
		Monaco~Monaco~43.74~7.41~36371;Vaduz~Liechtenstein~47.13~9.52~36281;
		Saint John's~Antigua and Barbuda~17.12~-61.85~35499;Saint George's~Grenada~12.05~-61.74~33734;
		Victoria~Seychelles~-4.62~55.45~33576;San Marino~San Marino~43.94~12.44~29579;
		Tarawa~Kiribati~1.34~173.02~28802;Majuro~Marshall Islands~7.1~171.38~25400;
		Roseau~Dominica~15.3~-61.39~23336;Basseterre~Saint Kitts and Nevis~17.3~-62.72~21887;
		Belmopan~Belize~17.25~-88.77~15220;Lobamba~eSwatini~-26.47~31.2~9782;
		Melekeok~Palau~7.49~134.63~7026;Funafuti~Tuvalu~-8.52~179.22~4749;
		Palikir~Federated States of Micronesia~6.92~158.15~4645;Vatican City~Vatican~41.9~12.45~832;
		Bir Lehlou~Western Sahara~26.12~-9.65~500;
	]"

end
