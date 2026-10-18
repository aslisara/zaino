import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/gestures.dart' show PointerScrollEvent;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'main.dart' show AiGuidePage, baseUrl, authHeaders;
import 'world_data.dart';

// ---------------- VERİ ----------------
class Country {
  final String name;
  final double lat;
  final double lon;
  final List<String> cities;
  const Country(this.name, this.lat, this.lon, this.cities);
}

const List<Country> kCountries = [
  Country('Türkiye', 39.0, 35.0, ['İstanbul', 'Ankara', 'İzmir', 'Antalya', 'Kapadokya', 'Bodrum', 'Trabzon', 'Bursa', 'Pamukkale', 'Mardin', 'Marmaris', 'Çanakkale']),
  Country('İtalya', 42.8, 12.5, ['Roma', 'Venedik', 'Floransa', 'Milano', 'Napoli', 'Amalfi', 'Cenova', 'Bologna', 'Torino', 'Verona', 'Pisa', 'Palermo']),
  Country('Fransa', 46.6, 2.3, ['Paris', 'Nice', 'Lyon', 'Marsilya', 'Bordeaux', 'Strazburg', 'Toulouse', 'Cannes', 'Mont Saint-Michel', 'Chamonix']),
  Country('İspanya', 40.4, -3.7, ['Barselona', 'Madrid', 'Sevilla', 'Valensiya', 'Granada', 'Malaga', 'Bilbao', 'San Sebastian', 'Palma', 'Toledo']),
  Country('Almanya', 51.1, 10.4, ['Berlin', 'Münih', 'Hamburg', 'Köln', 'Frankfurt', 'Dresden', 'Heidelberg', 'Stuttgart', 'Nürnberg', 'Düsseldorf']),
  Country('Yunanistan', 39.0, 22.0, ['Atina', 'Santorini', 'Selanik', 'Girit', 'Mikonos', 'Rodos', 'Korfu', 'Meteora', 'Nafplio']),
  Country('Birleşik Krallık', 54.0, -2.5, ['Londra', 'Edinburgh', 'Manchester', 'Liverpool', 'Oxford', 'Cambridge', 'Bath', 'Glasgow', 'Cardiff', 'York']),
  Country('Hollanda', 52.2, 5.3, ['Amsterdam', 'Rotterdam', 'Lahey', 'Utrecht', 'Eindhoven', 'Haarlem', 'Delft', 'Leiden']),
  Country('Portekiz', 39.5, -8.0, ['Lizbon', 'Porto', 'Faro', 'Sintra', 'Madeira', 'Coimbra', 'Lagos', 'Azor Adaları']),
  Country('İsviçre', 46.8, 8.2, ['Zürih', 'Cenevre', 'Luzern', 'Interlaken', 'Bern', 'Basel', 'Zermatt', 'Lozan']),
  Country('Avusturya', 47.5, 14.5, ['Viyana', 'Salzburg', 'Innsbruck', 'Hallstatt', 'Graz', 'Linz']),
  Country('Belçika', 50.6, 4.6, ['Brüksel', 'Brugge', 'Anvers', 'Gent']),
  Country('Çekya', 49.8, 15.5, ['Prag', 'Brno', 'Karlovy Vary', 'Český Krumlov', 'Olomouc', 'Pilsen']),
  Country('Macaristan', 47.2, 19.5, ['Budapeşte', 'Eger', 'Szeged', 'Pécs', 'Debrecen', 'Balaton']),
  Country('Polonya', 52.0, 19.1, ['Varşova', 'Krakov', 'Gdansk', 'Wroclaw', 'Poznan', 'Zakopane', 'Lublin']),
  Country('Hırvatistan', 45.1, 15.2, ['Dubrovnik', 'Split', 'Zagreb', 'Hvar', 'Zadar', 'Rovinj', 'Pula', 'Plitvice']),
  Country('İsveç', 62.0, 15.0, ['Stockholm', 'Göteborg', 'Malmö', 'Uppsala', 'Kiruna', 'Visby']),
  Country('Norveç', 61.0, 9.0, ['Oslo', 'Bergen', 'Tromsø', 'Stavanger', 'Lofoten', 'Trondheim']),
  Country('Danimarka', 56.0, 9.5, ['Kopenhag', 'Aarhus', 'Odense']),
  Country('Finlandiya', 64.0, 26.0, ['Helsinki', 'Rovaniemi', 'Tampere']),
  Country('İrlanda', 53.2, -8.2, ['Dublin', 'Galway', 'Cork']),
  Country('İzlanda', 64.9, -18.5, ['Reykjavik', 'Akureyri', 'Vik']),
  Country('Romanya', 45.9, 25.0, ['Bükreş', 'Brașov', 'Sibiu', 'Cluj-Napoca']),
  Country('Bulgaristan', 42.7, 25.3, ['Sofya', 'Plovdiv', 'Varna']),
  Country('Sırbistan', 44.0, 21.0, ['Belgrad', 'Novi Sad', 'Niş']),
  Country('Bosna Hersek', 44.0, 17.8, ['Saraybosna', 'Mostar', 'Banja Luka']),
  Country('Karadağ', 42.7, 19.3, ['Kotor', 'Budva', 'Podgorica']),
  Country('Arnavutluk', 41.1, 20.0, ['Tiran', 'Saranda', 'Berat']),
  Country('Malta', 35.9, 14.4, ['Valletta', 'Sliema', 'Mdina']),
  Country('Kıbrıs', 35.0, 33.3, ['Larnaka', 'Baf', 'Limasol']),
  Country('Rusya', 60.0, 90.0, ['Moskova', 'St. Petersburg', 'Kazan', 'Soçi', 'Yekaterinburg', 'Novosibirsk', 'Vladivostok']),
  Country('Gürcistan', 42.3, 43.4, ['Tiflis', 'Batum', 'Kazbegi', 'Kutaisi', 'Mestia', 'Signagi']),
  Country('Azerbaycan', 40.4, 47.7, ['Bakü', 'Şeki', 'Gabala']),
  Country('Japonya', 36.0, 138.0, ['Tokyo', 'Kyoto', 'Osaka', 'Nara', 'Hiroşima', 'Sapporo', 'Fukuoka', 'Kanazawa', 'Nagoya', 'Okinawa']),
  Country('Güney Kore', 36.5, 127.9, ['Seul', 'Busan', 'Jeju', 'Gyeongju', 'Incheon', 'Daegu', 'Jeonju']),
  Country('Çin', 35.0, 103.0, ['Pekin', 'Şanghay', 'Şian', 'Hong Kong', 'Chengdu', 'Guangzhou', 'Guilin', 'Hangzhou', 'Makao', 'Shenzhen']),
  Country('Tayland', 15.0, 101.0, ['Bangkok', 'Phuket', 'Chiang Mai', 'Krabi', 'Pattaya', 'Koh Samui', 'Ayutthaya', 'Hua Hin']),
  Country('Vietnam', 16.0, 107.8, ['Hanoi', 'Ho Chi Minh', 'Da Nang', 'Hoi An', 'Hue', 'Nha Trang', 'Ha Long', 'Sapa']),
  Country('Kamboçya', 12.6, 104.9, ['Siem Reap', 'Phnom Penh', 'Sihanoukville']),
  Country('Endonezya', -2.0, 118.0, ['Bali', 'Cakarta', 'Yogyakarta', 'Lombok', 'Bandung', 'Komodo', 'Surabaya']),
  Country('Malezya', 4.2, 102.0, ['Kuala Lumpur', 'Penang', 'Langkawi', 'Malakka', 'Kota Kinabalu', 'Johor Bahru']),
  Country('Filipinler', 12.9, 122.0, ['Manila', 'Cebu', 'Palawan', 'Boracay', 'Davao', 'Bohol', 'Siargao']),
  Country('Hindistan', 22.0, 79.0, ['Delhi', 'Mumbai', 'Jaipur', 'Agra', 'Goa', 'Varanasi', 'Kerala', 'Udaipur', 'Bangalore', 'Kolkata']),
  Country('Nepal', 28.4, 84.0, ['Katmandu', 'Pokhara', 'Lumbini']),
  Country('Sri Lanka', 7.9, 80.7, ['Kolombo', 'Kandy', 'Galle', 'Ella']),
  Country('Özbekistan', 41.4, 64.6, ['Semerkant', 'Buhara', 'Taşkent', 'Hive', 'Fergana']),
  Country('Kazakistan', 48.0, 67.0, ['Astana', 'Almatı', 'Şımkent']),
  Country('BAE', 24.3, 54.0, ['Dubai', 'Abu Dabi', 'Şarika', 'Ras El-Hayme', 'Fujeyra', 'Al Ain']),
  Country('Katar', 25.3, 51.2, ['Doha']),
  Country('Suudi Arabistan', 24.0, 45.0, ['Riyad', 'Cidde', 'AlUla', 'Mekke', 'Medine', 'Dammam']),
  Country('İsrail', 31.0, 34.9, ['Kudüs', 'Tel Aviv', 'Hayfa']),
  Country('Ürdün', 31.0, 36.5, ['Amman', 'Petra', 'Akabe', 'Wadi Rum', 'Cerş', 'Ölü Deniz']),
  Country('Mısır', 26.8, 30.8, ['Kahire', 'Luksor', 'Aswan', 'Hurghada', 'İskenderiye', 'Şarm El-Şeyh', 'Dahab']),
  Country('Fas', 31.8, -7.1, ['Marakeş', 'Fes', 'Kazablanka', 'Şefşaven', 'Rabat', 'Tanca', 'Essaouira', 'Agadir']),
  Country('Tunus', 34.0, 9.5, ['Tunus', 'Sidi Bu Said', 'Hammamet', 'Cerbe']),
  Country('Kenya', 0.2, 37.9, ['Nairobi', 'Mombasa', 'Maasai Mara', 'Diani', 'Nakuru']),
  Country('Tanzanya', -6.4, 34.9, ['Zanzibar', 'Arusha', 'Dar es Salaam', 'Serengeti', 'Kilimanjaro']),
  Country('Güney Afrika', -29.0, 24.0, ['Cape Town', 'Johannesburg', 'Durban', 'Pretoria', 'Port Elizabeth', 'Stellenbosch', 'Kruger']),
  Country('ABD', 39.8, -98.5, ['New York', 'Los Angeles', 'San Francisco', 'Chicago', 'Las Vegas', 'Miami', 'Washington', 'Boston', 'Seattle', 'New Orleans', 'Orlando', 'San Diego']),
  Country('Kanada', 56.0, -96.0, ['Toronto', 'Vancouver', 'Montreal', 'Quebec', 'Calgary', 'Ottawa', 'Banff', 'Niagara', 'Victoria']),
  Country('Meksika', 23.6, -102.5, ['Mexico City', 'Cancún', 'Tulum', 'Oaxaca', 'Guadalajara', 'Playa del Carmen', 'Puerto Vallarta', 'Merida']),
  Country('Küba', 21.5, -79.0, ['Havana', 'Varadero', 'Trinidad']),
  Country('Kosta Rika', 9.9, -84.0, ['San José', 'Arenal', 'Manuel Antonio']),
  Country('Kolombiya', 4.6, -74.3, ['Bogota', 'Medellín', 'Cartagena', 'Cali', 'Santa Marta', 'Salento']),
  Country('Peru', -9.2, -75.0, ['Lima', 'Cusco', 'Machu Picchu', 'Arequipa', 'Puno', 'Huacachina']),
  Country('Brezilya', -10.0, -52.0, ['Rio de Janeiro', 'São Paulo', 'Salvador', 'Florianópolis', 'Brasília', 'Recife', 'Foz do Iguaçu', 'Manaus']),
  Country('Şili', -35.7, -71.5, ['Santiago', 'Valparaíso', 'Patagonya', 'Atacama', 'Paskalya Adası', 'Punta Arenas']),
  Country('Arjantin', -34.0, -64.0, ['Buenos Aires', 'Mendoza', 'Bariloche', 'Ushuaia', 'Córdoba', 'Salta', 'El Calafate']),
  Country('Avustralya', -25.0, 134.0, ['Sidney', 'Melbourne', 'Brisbane', 'Perth', 'Adelaide', 'Gold Coast', 'Cairns', 'Canberra', 'Hobart']),
  Country('Yeni Zelanda', -41.0, 172.5, ['Auckland', 'Queenstown', 'Wellington', 'Christchurch', 'Rotorua', 'Milford Sound']),
  Country('Andorra', 42.5, 1.6, ['Andorra la Vella', 'Ordino']),
  Country('Belarus', 53.7, 27.9, ['Minsk', 'Brest', 'Grodno']),
  Country('Estonya', 58.6, 25.0, ['Tallinn', 'Tartu', 'Pärnu']),
  Country('Letonya', 56.9, 24.6, ['Riga', 'Jūrmala', 'Cēsis']),
  Country('Litvanya', 55.2, 23.9, ['Vilnius', 'Kaunas', 'Klaipėda']),
  Country('Lüksemburg', 49.8, 6.1, ['Lüksemburg', 'Vianden']),
  Country('Moldova', 47.4, 28.4, ['Kişinev', 'Orhei']),
  Country('Monako', 43.74, 7.42, ['Monako', 'Monte Carlo']),
  Country('Kuzey Makedonya', 41.6, 21.7, ['Üsküp', 'Ohrid', 'Bitola']),
  Country('Slovakya', 48.7, 19.7, ['Bratislava', 'Košice', 'Poprad']),
  Country('Slovenya', 46.1, 14.8, ['Ljubljana', 'Bled', 'Piran']),
  Country('Ukrayna', 49.0, 32.0, ['Kiev', 'Lviv', 'Odessa']),
  Country('San Marino', 43.94, 12.46, ['San Marino']),
  Country('Liechtenstein', 47.17, 9.55, ['Vaduz']),
  Country('Vatikan', 41.9, 12.45, ['Vatikan']),
  Country('Kosova', 42.6, 20.9, ['Priştine', 'Prizren', 'Peja']),
  Country('Afganistan', 33.9, 67.7, ['Kabil', 'Herat', 'Mezar-ı Şerif']),
  Country('Bahreyn', 26.0, 50.55, ['Manama', 'Muharrak']),
  Country('Bangladeş', 23.7, 90.4, ['Dakka', 'Chittagong', 'Cox Bazar']),
  Country('Butan', 27.5, 90.4, ['Thimphu', 'Paro', 'Punakha']),
  Country('Brunei', 4.5, 114.7, ['Bandar Seri Begawan']),
  Country('Doğu Timor', -8.8, 125.7, ['Dili', 'Baucau']),
  Country('Ermenistan', 40.1, 45.0, ['Erivan', 'Gümrü', 'Dilican']),
  Country('Irak', 33.2, 43.7, ['Bağdat', 'Erbil', 'Basra']),
  Country('İran', 32.4, 53.7, ['Tahran', 'İsfahan', 'Şiraz']),
  Country('Kuveyt', 29.3, 47.5, ['Kuveyt']),
  Country('Kırgızistan', 41.2, 74.8, ['Bişkek', 'Issık Göl', 'Oş']),
  Country('Laos', 19.9, 102.5, ['Vientiane', 'Luang Prabang', 'Vang Vieng']),
  Country('Lübnan', 33.9, 35.9, ['Beyrut', 'Baalbek', 'Byblos']),
  Country('Maldivler', 3.2, 73.2, ['Male', 'Maafushi']),
  Country('Moğolistan', 46.9, 103.8, ['Ulan Batur', 'Karakurum']),
  Country('Myanmar', 21.9, 96.0, ['Yangon', 'Bagan', 'Mandalay']),
  Country('Kuzey Kore', 40.3, 127.5, ['Pyongyang']),
  Country('Umman', 21.5, 55.9, ['Maskat', 'Salala', 'Nizva']),
  Country('Pakistan', 30.4, 69.3, ['İslamabad', 'Lahor', 'Karaçi']),
  Country('Singapur', 1.35, 103.8, ['Singapur']),
  Country('Suriye', 34.8, 38.9, ['Şam', 'Halep', 'Palmira']),
  Country('Tacikistan', 38.9, 71.3, ['Duşanbe', 'Hocent']),
  Country('Türkmenistan', 39.0, 59.6, ['Aşkabat', 'Merv']),
  Country('Yemen', 15.6, 48.5, ['Sana', 'Aden', 'Sokotra']),
  Country('Tayvan', 23.7, 121.0, ['Taipei', 'Kaohsiung', 'Taichung']),
  Country('Cezayir', 28.0, 2.6, ['Cezayir', 'Oran', 'Konstantin']),
  Country('Angola', -11.2, 17.9, ['Luanda', 'Lubango']),
  Country('Benin', 9.3, 2.3, ['Porto-Novo', 'Cotonou']),
  Country('Botsvana', -22.3, 24.7, ['Gaborone', 'Maun', 'Kasane']),
  Country('Burkina Faso', 12.2, -1.6, ['Wagadugu', 'Bobo-Dioulasso']),
  Country('Burundi', -3.4, 29.9, ['Gitega', 'Bujumbura']),
  Country('Kamerun', 7.4, 12.4, ['Yaoundé', 'Douala']),
  Country('Yeşil Burun', 16.0, -24.0, ['Praia', 'Mindelo', 'Sal']),
  Country('Orta Afrika Cumhuriyeti', 6.6, 20.9, ['Bangui']),
  Country('Çad', 15.5, 18.7, ['Encamina']),
  Country('Komorlar', -11.9, 43.9, ['Moroni']),
  Country('Kongo', -0.7, 15.2, ['Brazzaville', 'Pointe-Noire']),
  Country('Kongo Demokratik Cumhuriyeti', -2.9, 23.7, ['Kinşasa', 'Goma', 'Lubumbashi']),
  Country('Cibuti', 11.8, 42.6, ['Cibuti', 'Tacura']),
  Country('Ekvator Ginesi', 1.6, 10.5, ['Malabo', 'Bata']),
  Country('Eritre', 15.2, 39.8, ['Asmara', 'Massawa']),
  Country('Esvatini', -26.5, 31.5, ['Mbabane', 'Lobamba']),
  Country('Etiyopya', 9.1, 40.5, ['Addis Ababa', 'Lalibela', 'Gondar']),
  Country('Gabon', -0.8, 11.6, ['Librevil', 'Port-Gentil']),
  Country('Gambiya', 13.4, -15.3, ['Banjul', 'Serekunda']),
  Country('Gana', 7.9, -1.0, ['Akra', 'Kumasi', 'Cape Coast']),
  Country('Gine', 9.9, -11.0, ['Konakri']),
  Country('Gine-Bissau', 12.0, -15.2, ['Bissau', 'Bijagos']),
  Country('Fildişi Sahili', 7.5, -5.5, ['Abidjan', 'Yamusukro']),
  Country('Lesotho', -29.6, 28.2, ['Maseru', 'Thaba-Bosiu']),
  Country('Liberya', 6.4, -9.4, ['Monrovya']),
  Country('Libya', 27.0, 17.0, ['Trablus', 'Bingazi', 'Leptis Magna']),
  Country('Madagaskar', -19.0, 46.7, ['Antananarivo', 'Nosy Be']),
  Country('Malavi', -13.3, 34.3, ['Lilongwe', 'Blantyre']),
  Country('Mali', 17.6, -3.5, ['Bamako', 'Timbuktu', 'Djenné']),
  Country('Moritanya', 20.3, -10.9, ['Nuakşot', 'Şinguetti']),
  Country('Mauritius', -20.3, 57.6, ['Port Louis', 'Grand Baie']),
  Country('Mozambik', -18.7, 35.5, ['Maputo', 'Vilankulo', 'Tofo']),
  Country('Namibya', -22.6, 17.1, ['Windhoek', 'Swakopmund', 'Sossusvlei']),
  Country('Nijer', 17.6, 8.1, ['Niamey', 'Agadez']),
  Country('Nijerya', 9.1, 8.7, ['Abuja', 'Lagos', 'Kano']),
  Country('Ruanda', -1.9, 29.9, ['Kigali', 'Musanze']),
  Country('Sao Tome ve Principe', 0.2, 6.6, ['Sao Tome']),
  Country('Senegal', 14.5, -14.5, ['Dakar', 'Saint-Louis', 'Saly']),
  Country('Seyşeller', -4.7, 55.5, ['Victoria', 'Praslin', 'La Digue']),
  Country('Sierra Leone', 8.5, -11.8, ['Freetown', 'Bo']),
  Country('Somali', 5.2, 46.2, ['Mogadişu', 'Hargeisa']),
  Country('Güney Sudan', 7.9, 29.7, ['Cuba', 'Wau']),
  Country('Sudan', 15.6, 30.2, ['Hartum', 'Meroe']),
  Country('Togo', 8.6, 0.8, ['Lome', 'Kpalimé']),
  Country('Uganda', 1.4, 32.3, ['Kampala', 'Entebbe', 'Jinja']),
  Country('Zambiya', -13.1, 27.8, ['Lusaka', 'Livingstone']),
  Country('Zimbabve', -19.0, 29.2, ['Harare', 'Victoria Şelalesi', 'Bulawayo']),
  Country('Antigua ve Barbuda', 17.1, -61.8, ['Saint John']),
  Country('Bahamalar', 25.0, -77.4, ['Nassau', 'Exuma']),
  Country('Barbados', 13.2, -59.5, ['Bridgetown', 'Holetown']),
  Country('Belize', 17.2, -88.5, ['Belize City', 'San Pedro', 'Placencia']),
  Country('Bolivya', -16.3, -63.6, ['La Paz', 'Sucre', 'Uyuni']),
  Country('Dominika', 15.4, -61.4, ['Roseau']),
  Country('Dominik Cumhuriyeti', 18.7, -70.2, ['Santo Domingo', 'Punta Cana', 'Puerto Plata']),
  Country('Ekvador', -1.8, -78.2, ['Quito', 'Guayaquil', 'Galápagos']),
  Country('El Salvador', 13.8, -88.9, ['San Salvador', 'El Tunco']),
  Country('Grenada', 12.1, -61.7, ['St. George']),
  Country('Guatemala', 15.8, -90.2, ['Guatemala City', 'Antigua', 'Flores']),
  Country('Guyana', 4.9, -58.9, ['Georgetown', 'Kaieteur']),
  Country('Haiti', 19.1, -72.3, ['Port-au-Prince', 'Cap-Haïtien']),
  Country('Honduras', 15.2, -86.2, ['Tegucigalpa', 'Roatán', 'Copán']),
  Country('Jamaika', 18.1, -77.3, ['Kingston', 'Montego Bay', 'Negril']),
  Country('Nikaragua', 12.9, -85.2, ['Managua', 'Granada', 'León']),
  Country('Panama', 8.5, -80.8, ['Panama City', 'Bocas del Toro']),
  Country('Paraguay', -23.4, -58.4, ['Asunción', 'Encarnación']),
  Country('Surinam', 3.9, -56.0, ['Paramaribo']),
  Country('Trinidad ve Tobago', 10.7, -61.2, ['Port of Spain', 'Tobago']),
  Country('Uruguay', -32.5, -55.8, ['Montevideo', 'Punta del Este', 'Colonia']),
  Country('Venezuela', 6.4, -66.6, ['Karakas', 'Mérida', 'Angel Şelalesi']),
  Country('Saint Kitts ve Nevis', 17.3, -62.7, ['Basseterre']),
  Country('Saint Lucia', 13.9, -60.98, ['Castries', 'Soufrière']),
  Country('Saint Vincent ve Grenadinler', 13.25, -61.2, ['Kingstown', 'Bequia']),
  Country('Fiji', -17.7, 178.1, ['Suva', 'Nadi', 'Denarau']),
  Country('Papua Yeni Gine', -6.3, 143.9, ['Port Moresby', 'Madang']),
  Country('Samoa', -13.76, -172.1, ['Apia']),
  Country('Solomon Adaları', -9.6, 160.2, ['Honiara']),
  Country('Tonga', -21.2, -175.2, ['Nukuʻalofa']),
  Country('Vanuatu', -15.4, 166.96, ['Port Vila', 'Espiritu Santo']),
  Country('Kiribati', 1.9, -157.4, ['Tarawa', 'Kiritimati']),
  Country('Mikronezya', 6.9, 158.2, ['Palikir', 'Pohnpei']),
  Country('Marshall Adaları', 7.1, 171.2, ['Majuro']),
  Country('Nauru', -0.53, 166.93, ['Yaren']),
  Country('Palau', 7.5, 134.6, ['Koror', 'Rock Islands']),
  Country('Tuvalu', -7.1, 177.6, ['Funafuti']),
];

// ---------------- EKRAN ----------------
class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});
  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> with TickerProviderStateMixin {
  double _lon0 = 35; // küre merkezinin boylamı
  double _lat0 = 25; // küre merkezinin enlemi
  Country? _selected;
  bool _auto = true;
  String _query = '';
  double _zoom = 1;
  double _zoom0 = 1;
  final Map<String, List<String>> _extra = {}; // ülke -> yapay zekâdan gelen ek şehirler
  String? _loadingMore;
  String? _moreError;
  final _cityInput = TextEditingController();

  late final AnimationController _spin;
  AnimationController? _fly;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..addListener(() {
        if (_auto && mounted) setState(() => _lon0 = _wrap(_lon0 + 0.12));
      })
      ..repeat();
  }

  @override
  void dispose() {
    _spin.dispose();
    _cityInput.dispose();
    _fly?.dispose();
    super.dispose();
  }

  double _wrap(double lon) {
    var l = lon;
    while (l > 180) {
      l -= 360;
    }
    while (l < -180) {
      l += 360;
    }
    return l;
  }

  // Türkçe harfleri sadeleştirir: "İtalya" ve "italya" aynı sayılır
  String _fold(String t) {
    const from = 'İIıÇçĞğÖöŞşÜü';
    const to = 'iiiccggoossuu';
    final b = StringBuffer();
    for (final r in t.runes) {
      final ch = String.fromCharCode(r);
      final i = from.indexOf(ch);
      b.write(i >= 0 ? to[i] : ch.toLowerCase());
    }
    return b.toString();
  }

  void _select(Country c) {
    _auto = false;
    setState(() => _selected = c);
    _fly?.dispose();
    final fromLon = _lon0;
    final fromLat = _lat0;
    var dLon = c.lon - fromLon;
    while (dLon > 180) {
      dLon -= 360;
    }
    while (dLon < -180) {
      dLon += 360;
    }
    final dLat = c.lat.clamp(-60.0, 60.0) - fromLat;
    final ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    final curve = CurvedAnimation(parent: ctrl, curve: Curves.easeInOut);
    ctrl.addListener(() {
      if (!mounted) return;
      setState(() {
        _lon0 = _wrap(fromLon + dLon * curve.value);
        _lat0 = fromLat + dLat * curve.value;
      });
    });
    _fly = ctrl;
    ctrl.forward();
  }

  String _extractText(dynamic json) {
    if (json is String) return json;
    if (json is Map) {
      for (final k in ['answer', 'text', 'content', 'response', 'reply', 'message', 'result']) {
        if (json[k] is String) return json[k] as String;
      }
      for (final v in json.values) {
        if (v is String) return v;
      }
    }
    return jsonEncode(json);
  }

  Future<void> _loadMore(Country c) async {
    setState(() {
      _loadingMore = c.name;
      _moreError = null;
    });
    try {
      final prompt = '${c.name} ülkesinde gezilecek en popüler 15 şehir veya bölgeyi yaz. '
          'Sadece adları Türkçe yaz, virgülle ayır, tek satırda ver. '
          'Numara, açıklama ya da başka hiçbir şey yazma.';
      final res = await http.post(
        Uri.parse('$baseUrl/api/ai'),
        headers: authHeaders(),
        body: jsonEncode({'prompt': prompt}),
      );
      if (res.statusCode != 200) {
        throw Exception('Sunucu ${res.statusCode} döndü');
      }
      final text = _extractText(jsonDecode(utf8.decode(res.bodyBytes)));
      final known = c.cities.map((e) => e.toLowerCase()).toSet();
      final list = text
          .split(RegExp(r'[,\n;]'))
          .map((e) => e.replaceAll(RegExp(r'^[\s\d\.\-\*•]+'), '').replaceAll(RegExp(r'[*_]'), '').trim())
          .where((e) => e.isNotEmpty && e.length < 40 && !known.contains(e.toLowerCase()))
          .toSet()
          .toList();
      if (list.isEmpty) throw Exception('Şehir listesi boş geldi');
      if (!mounted) return;
      setState(() => _extra[c.name] = list);
    } catch (e) {
      if (!mounted) return;
      setState(() => _moreError = 'Daha fazla şehir alınamadı: $e');
    } finally {
      if (mounted) setState(() => _loadingMore = null);
    }
  }

  void _openGuide(Country c, String city) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AiGuidePage(initialCity: city, initialCountry: c.name),
      ),
    );
  }

  void _onTap(Offset pos, Size size) {
    final proj = _GlobeProjector(size, _lon0, _lat0, _zoom);
    Country? best;
    var bestDist = 22.0;
    for (final c in kCountries) {
      final p = proj.project(c.lat, c.lon);
      if (p.z <= 0.05) continue;
      final d = (p.offset - pos).distance;
      if (d < bestDist) {
        bestDist = d;
        best = c;
      }
    }
    if (best != null) _select(best);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final sel = _selected;
    final shown = kCountries
        .where((c) => _query.isEmpty || _fold(c.name).contains(_fold(_query)))
        .toList()
      ..sort((a, b) => _fold(a.name).compareTo(_fold(b.name)));
    return Scaffold(
      appBar: AppBar(title: const Text('Keşfet')),
      body: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, box) {
                final size = Size(box.maxWidth, box.maxHeight);
                return Listener(
                  onPointerSignal: (e) {
                    if (e is PointerScrollEvent) {
                      _auto = false;
                      setState(() {
                        _zoom = (_zoom - e.scrollDelta.dy * 0.002).clamp(1.0, 6.0);
                      });
                    }
                  },
                  child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onScaleStart: (_) {
                    _auto = false;
                    _zoom0 = _zoom;
                  },
                  onScaleUpdate: (d) {
                    setState(() {
                      _zoom = (_zoom0 * d.scale).clamp(1.0, 6.0);
                      final k = 0.45 / _zoom;
                      _lon0 = _wrap(_lon0 - d.focalPointDelta.dx * k);
                      _lat0 = (_lat0 + d.focalPointDelta.dy * k).clamp(-75.0, 75.0);
                    });
                  },
                  onTapUp: (d) => _onTap(d.localPosition, size),
                  child: ClipRect(
                  child: CustomPaint(
                    size: size,
                    painter: _GlobePainter(
                      lon0: _lon0,
                      lat0: _lat0,
                      zoom: _zoom,
                      selected: sel,
                      marker: cs.tertiary,
                      markerSel: cs.error,
                    ),
                  ),
                  ),
                  ),
                );
              },
            ),
          ),
          if (sel == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text(
                'Küreyi döndür, bir noktaya dokun ya da aşağıdan ülke seç.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            )
          else
            Card(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.32,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(sel.name, style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 6),
                      Text('Şehir seç, yapay zekâ rehberi açılsın:',
                          style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          for (final city in [...sel.cities, ...?_extra[sel.name]])
                            ActionChip(
                              avatar: const Icon(Icons.location_city, size: 18),
                              label: Text(city),
                              onPressed: () => _openGuide(sel, city),
                            ),
                          if (_extra[sel.name] == null)
                            ActionChip(
                              avatar: _loadingMore == sel.name
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.add, size: 18),
                              label: Text(_loadingMore == sel.name
                                  ? 'Yükleniyor...'
                                  : 'Daha fazla şehir'),
                              onPressed: _loadingMore != null ? null : () => _loadMore(sel),
                            ),
                        ],
                      ),
                      if (_moreError != null) ...[
                        const SizedBox(height: 6),
                        Text(_moreError!,
                            style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12)),
                      ],
                      const SizedBox(height: 10),
                      TextField(
                        controller: _cityInput,
                        decoration: InputDecoration(
                          isDense: true,
                          labelText: 'Listede yok mu? Şehri kendin yaz',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.arrow_forward),
                            onPressed: () {
                              final t = _cityInput.text.trim();
                              if (t.isNotEmpty) _openGuide(sel, t);
                            },
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onSubmitted: (t) {
                          if (t.trim().isNotEmpty) _openGuide(sel, t.trim());
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
            child: TextField(
              decoration: InputDecoration(
                isDense: true,
                prefixIcon: const Icon(Icons.search),
                hintText: 'Ülke ara (${kCountries.length} ülke)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
              ),
              onChanged: (v) => setState(() => _query = v.trim()),
            ),
          ),
          SizedBox(
            height: 52,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: shown.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final c = shown[i];
                return ChoiceChip(
                  label: Text(c.name),
                  selected: sel == c,
                  onSelected: (_) => _select(c),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

// ---------------- PROJEKSİYON ----------------
class _Projected {
  final Offset offset;
  final double z; // >0: küre önünde (görünür)
  const _Projected(this.offset, this.z);
}

class _GlobeProjector {
  final Size size;
  final double lon0;
  final double lat0;
  final double zoom;
  late final double radius;
  late final Offset center;

  _GlobeProjector(this.size, this.lon0, this.lat0, [this.zoom = 1]) {
    radius = math.min(size.width, size.height) * 0.46 * zoom;
    center = Offset(size.width / 2, size.height / 2);
  }

  static double _rad(double d) => d * math.pi / 180;

  _Projected project(double lat, double lon) {
    final phi = _rad(lat);
    final phi0 = _rad(lat0);
    final dl = _rad(lon - lon0);
    final x = math.cos(phi) * math.sin(dl);
    final y = math.cos(phi0) * math.sin(phi) - math.sin(phi0) * math.cos(phi) * math.cos(dl);
    final z = math.sin(phi0) * math.sin(phi) + math.cos(phi0) * math.cos(phi) * math.cos(dl);
    return _Projected(Offset(center.dx + radius * x, center.dy - radius * y), z);
  }

  /// Görünmeyen (arka) noktaları kürenin kenarına yapıştırır.
  Offset projectClamped(double lat, double lon) {
    final p = project(lat, lon);
    if (p.z >= 0) return p.offset;
    final v = p.offset - center;
    final len = v.distance;
    if (len == 0) return center + Offset(radius, 0);
    return center + v / len * radius;
  }
}

// ---------------- GERÇEK HARİTA VERİSİ ----------------
List<List<double>> _parseLines(String data, {double maxStep = 0}) {
  final out = <List<double>>[];
  for (final ring in data.split('|')) {
    if (ring.isEmpty) continue;
    final flat = <double>[];
    double? pLat, pLon;
    for (final pt in ring.split(';')) {
      final i = pt.indexOf(',');
      final lat = double.parse(pt.substring(0, i));
      final lon = double.parse(pt.substring(i + 1));
      if (maxStep > 0 && pLat != null) {
        // ±180° çizgisini geçen kenarı kısa yoldan birleştir
        var lon2 = lon;
        if (lon2 - pLon! > 180) lon2 -= 360;
        if (lon2 - pLon < -180) lon2 += 360;
        final d = math.max((lat - pLat).abs(), (lon2 - pLon).abs());
        final n = (d / maxStep).ceil();
        for (var k = 1; k < n; k++) {
          final t = k / n;
          flat.add(pLat + (lat - pLat) * t);
          flat.add(pLon + (lon2 - pLon) * t);
        }
      }
      flat.add(lat);
      flat.add(lon);
      pLat = lat;
      pLon = lon;
    }
    out.add(flat);
  }
  return out;
}

final List<List<double>> kLandRings = _parseLines(kLandData, maxStep: 2.5);
final List<List<double>> kBorderLines = _parseLines(kBorderData);

// ---------------- ÇİZİM ----------------
class _GlobePainter extends CustomPainter {
  final double lon0;
  final double lat0;
  final double zoom;
  final Country? selected;
  final Color marker;
  final Color markerSel;

  _GlobePainter({
    required this.lon0,
    required this.lat0,
    required this.zoom,
    required this.selected,
    required this.marker,
    required this.markerSel,
  });

  static const _oceanLight = Color(0xFF3F8FD8);
  static const _oceanMid = Color(0xFF1F5FB0);
  static const _oceanDark = Color(0xFF0B2A5E);
  static const _landLight = Color(0xFF8CCB8A);
  static const _landDark = Color(0xFF4E9A63);

  @override
  void paint(Canvas canvas, Size size) {
    final proj = _GlobeProjector(size, lon0, lat0, zoom);
    final c = proj.center;
    final r = proj.radius;
    final full = Rect.fromLTWH(0, 0, size.width, size.height);
    final disc = Rect.fromCircle(center: c, radius: r);

    // uzay arka planı
    canvas.drawRect(
      full,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFF14264D), Color(0xFF070D20)],
        ).createShader(full),
    );
    // sabit yıldızlar
    final rnd = math.Random(7);
    final star = Paint();
    for (var i = 0; i < 70; i++) {
      final o = Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height);
      star.color = Colors.white.withValues(alpha: 0.15 + rnd.nextDouble() * 0.5);
      canvas.drawCircle(o, 0.4 + rnd.nextDouble() * 1.1, star);
    }

    // atmosfer parıltısı
    final halo = Rect.fromCircle(center: c, radius: r * 1.16);
    canvas.drawCircle(
      c,
      r * 1.16,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0x00000000), Color(0x00000000), Color(0x664FA8FF), Color(0x004FA8FF)],
          stops: [0.0, 0.84, 0.865, 1.0],
        ).createShader(halo),
    );

    // okyanus
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.45, -0.45),
          radius: 1.25,
          colors: [_oceanLight, _oceanMid, _oceanDark],
          stops: [0.0, 0.5, 1.0],
        ).createShader(disc),
    );

    canvas.save();
    canvas.clipPath(Path()..addOval(disc));

    // ızgara
    final grid = Paint()
      ..color = Colors.white.withValues(alpha: 0.09)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    for (var lat = -60; lat <= 60; lat += 30) {
      _strokeFlat(canvas, proj, grid,
          [for (var lon = -180; lon <= 180; lon += 4) ...[lat.toDouble(), lon.toDouble()]]);
    }
    for (var lon = -180; lon < 180; lon += 30) {
      _strokeFlat(canvas, proj, grid,
          [for (var lat = -88; lat <= 88; lat += 4) ...[lat.toDouble(), lon.toDouble()]]);
    }

    // karalar
    final landPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_landLight, _landDark],
      ).createShader(disc);
    final coast = Paint()
      ..color = const Color(0xFF2F6F47).withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;
    for (final ring in kLandRings) {
      final path = _clipRing(proj, ring);
      if (path == null) continue;
      canvas.drawPath(path, landPaint);
      canvas.drawPath(path, coast);
    }

    // ülke sınırları
    final border = Paint()
      ..color = Colors.white.withValues(alpha: zoom > 1.6 ? 0.55 : 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;
    for (final line in kBorderLines) {
      _strokeFlat(canvas, proj, border, line);
    }

    // ışık: sol üstte parlama, kenarlarda karartma
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.5, -0.5),
          radius: 0.9,
          colors: [Colors.white.withValues(alpha: 0.20), Colors.transparent],
        ).createShader(disc),
    );
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.42)],
          stops: const [0.68, 1.0],
        ).createShader(disc),
    );
    canvas.restore();

    // kenar çizgisi
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = const Color(0xFF8CC4FF).withValues(alpha: 0.5),
    );

    // ülke işaretleri
    final showAllLabels = zoom >= 2.4;
    for (final country in kCountries) {
      final p = proj.project(country.lat, country.lon);
      if (p.z <= 0.05) continue;
      final isSel = identical(country, selected);
      final scale = (0.6 + 0.4 * p.z) * (0.85 + 0.15 * zoom);
      if (isSel) {
        canvas.drawCircle(p.offset, 15 * scale, Paint()..color = markerSel.withValues(alpha: 0.25));
      }
      canvas.drawCircle(p.offset, (isSel ? 8.5 : 5.2) * scale, Paint()..color = Colors.white);
      canvas.drawCircle(
        p.offset,
        (isSel ? 6.0 : 3.5) * scale,
        Paint()..color = isSel ? markerSel : marker,
      );
      if (isSel || (showAllLabels && p.z > 0.25)) {
        final tp = TextPainter(
          text: TextSpan(
            text: country.name,
            style: TextStyle(
              color: Colors.white,
              fontSize: isSel ? 13.5 : 10.5,
              fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
              shadows: const [Shadow(blurRadius: 3, color: Colors.black87)],
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        final pos = p.offset + Offset(-tp.width / 2, isSel ? -28 : -18);
        if (isSel) {
          final pill = RRect.fromRectAndRadius(
            Rect.fromLTWH(pos.dx - 8, pos.dy - 3, tp.width + 16, tp.height + 6),
            const Radius.circular(12),
          );
          canvas.drawRRect(pill, Paint()..color = Colors.black.withValues(alpha: 0.55));
        }
        tp.paint(canvas, pos);
      }
    }
  }

  /// Kara halkasını kürenin görünen yarısına keser. Görünmeyen kısımlar,
  /// kürenin kenarı boyunca bir yayla birleştirilir.
  Path? _clipRing(_GlobeProjector proj, List<double> ring) {
    final n = ring.length ~/ 2;
    if (n < 3) return null;
    final c = proj.center;
    final r = proj.radius;
    final off = List<Offset>.filled(n, Offset.zero);
    final vis = List<bool>.filled(n, false);
    final zs = List<double>.filled(n, 0);
    var anyVis = false;
    var allVis = true;
    for (var i = 0; i < n; i++) {
      final p = proj.project(ring[2 * i], ring[2 * i + 1]);
      off[i] = p.offset;
      zs[i] = p.z;
      vis[i] = p.z >= 0;
      if (vis[i]) {
        anyVis = true;
      } else {
        allVis = false;
      }
    }
    if (!anyVis) return null;

    Offset toLimb(Offset o) {
      final v = o - c;
      final len = v.distance;
      if (len == 0) return c + Offset(r, 0);
      return c + v / len * r;
    }

    Offset cross(int i, int j) {
      final t = zs[i] / (zs[i] - zs[j]);
      return toLimb(Offset.lerp(off[i], off[j], t)!);
    }

    final path = Path();
    if (allVis) {
      path.moveTo(off[0].dx, off[0].dy);
      for (var i = 1; i < n; i++) {
        path.lineTo(off[i].dx, off[i].dy);
      }
      path.close();
      return path;
    }

    var start = -1;
    for (var i = 0; i < n; i++) {
      final prev = (i - 1 + n) % n;
      if (vis[i] && !vis[prev]) {
        start = i;
        break;
      }
    }
    if (start < 0) return null;

    final first = cross((start - 1 + n) % n, start);
    path.moveTo(first.dx, first.dy);
    Offset? exitP;
    for (var k = 0; k < n; k++) {
      final i = (start + k) % n;
      final j = (i + 1) % n;
      if (vis[i]) {
        path.lineTo(off[i].dx, off[i].dy);
        if (!vis[j]) {
          exitP = cross(i, j);
          path.lineTo(exitP.dx, exitP.dy);
        }
      } else if (vis[j] && exitP != null) {
        final ent = cross(i, j);
        final a0 = math.atan2(exitP.dy - c.dy, exitP.dx - c.dx);
        final a1 = math.atan2(ent.dy - c.dy, ent.dx - c.dx);
        var d = a1 - a0;
        while (d > math.pi) {
          d -= 2 * math.pi;
        }
        while (d < -math.pi) {
          d += 2 * math.pi;
        }
        path.arcTo(Rect.fromCircle(center: c, radius: r), a0, d, false);
        path.lineTo(ent.dx, ent.dy);
      }
    }
    path.close();
    return path;
  }

  /// [enlem, boylam, enlem, boylam, ...] düz listesini çizer; arka yüzü atlar.
  void _strokeFlat(Canvas canvas, _GlobeProjector proj, Paint paint, List<double> pts) {
    Path? path;
    for (var i = 0; i < pts.length; i += 2) {
      final q = proj.project(pts[i], pts[i + 1]);
      if (q.z <= 0) {
        if (path != null) canvas.drawPath(path, paint);
        path = null;
        continue;
      }
      if (path == null) {
        path = Path()..moveTo(q.offset.dx, q.offset.dy);
      } else {
        path.lineTo(q.offset.dx, q.offset.dy);
      }
    }
    if (path != null) canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _GlobePainter old) =>
      old.lon0 != lon0 || old.lat0 != lat0 || old.zoom != zoom || old.selected != selected;
}
