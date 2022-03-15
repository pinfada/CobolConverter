require 'pp'
require 'json'


class CobolConverter

	def main
		puts "initialisation et ouverture fichier"
		stopwords = %w{ASCENDING}
		File.open('cobol.cpy')
		trt_general(stopwords)
	end


	def trt_general(stw)
		a = ""
		fic = ""
		# data = ""
		ficenrg = ""
		word_count = 0
		line_count = 0
		puts "trt_general"
		File.foreach('cobol.cpy') do |line| 
			# puts "ligne : #{line}"
			# Detection "." en fin de ligne
			next if line.match(Regexp.union('*'))
				if  line.match(Regexp.union("."))
					fic << a
					fic << line
					# Suppression des espaces superflus
					ficenrg = fic.squeeze(' ').upcase
					#puts "ficenrg : #{ficenrg}"

					# Suppression saut de ligne
					# data =  ficenrg.gsub(/\s+/, ' ').strip
					#puts "ligne sauvegardée : #{a} #{line}"
					#puts "ligne ecrite :  #{data}"
					line_count += 1
					a = ""
				else
					a << line.gsub(/\s+/, ' ').strip
					#puts "ligne stockée : #{a}"
				end
		end
		trt_file(ficenrg)
		stats(ficenrg, line_count, stw)
	end

	def trt_file(data)
		# initilisation des variables
		sortie = []
		type_ws = ""
		value_ws = ""
		tablgr_ws =""
		depending_ws = ""
		ordertype_ws = ""
		indexed_ws = ""
		redefines_ws = ""
		commentaire_ws = ""
		longueur_ws = ""
		order_key_ws = ""
		comp_ws = ""
		thru_ws = ""
		getOccurs = ""
		getOrder = ""
		getIndex = ""
		ind_type = false
		ind_value = false
		ind_thru = false
		ind_occurs = false
		ind_order = false
		ind_index = false
		ind_redefines = false
		stock = ""
		i = 0

		# boucle sur les enregistrements du fichier
		data.each_line do |line|
			# contrôle presence donnée sur la ligne traitée
			test = ctrl_champs(line)

			i += 1
			values = line.split("")
			#puts "line #{i}: #{line}"
			niveau_ws = ""
			geThrue = ""
			variable_ws = ""
			longueur_ws = ""
			value_ws = ""
			thru_ws = ""
			occurs_ws = ""
			ordertype_ws = ""
			redefines_ws = ""
			order_key_ws = occurs_ws = indexed_ws = depending_ws = ""

			test.each_with_index do |val, index|
				case index
				when 0
					if  val == true
						longueur_ws = line.split("PIC").last.split(" ").first
						puts "LONGUEUR : #{longueur_ws}"
						# X --------------> alphanumérique 
						# A --------------> alphabétique 
						# 9 --------------> numérique non signé 
					    # S9 -------------> numérique signé 
						type_ws = determination_type(longueur_ws)
						# Permet de determiner si la picture contient des parentheses
						findbrackets = matching_brackets?(longueur_ws)
						if findbrackets == false
							lgr = longueur_ws[/\(.*?\)/]
							#puts "longueur numerique : #{lgr}"
						end
						#puts "contains brackets : #{findbrackets}"
						#puts "TYPE : #{type_ws}"
						stock = ""
					end

				when 1
					if  val == true
						geThrue = alim_champs_thru(line)
						if  !geThrue.nil?
							value_ws = line.split("VALUE").last.split("THRU").first
							thru_ws = line.split("THRU").last.split(".").first
							#puts "VALUE : #{value_ws} THRU : #{thru_ws}"
						else
							value_ws = line.split("VALUE").last.split(".").first
							thru_ws = ""
							#puts "VALUE : #{value_ws}"
						end
						stock = ""
					end

				when 2
					if  val == true
						occurs_ws = line.split("OCCURS").last.split("TIMES").first
						depending = alim_champs_depending(line)
						#puts "OCCURS : #{occurs_ws}"
						
						if  !depending.nil?
							depending_ws = line.split(" ON ").last.split("PIC").first
							#puts "DEPENDING : #{depending_ws}"
						else
							order_key_ws = line.split("IS").last.split("INDEXED").first
							indexed_ws = line.split("BY").last.split(".").first
							#puts "INDEXED : #{indexed_ws}"
							#puts "KEY : #{order_key_ws}"
						end
						stock = ""
					end

				when 3
					if  val == true
						ordertype_ws = line.split("TIMES").last.split("KEY").first
						#puts "ORDER : #{ordertype_ws}"
						stock = ""
					end

				when 4
					if  val == true
						redefines_ws = line.split("REDEFINES").last.split(".").first
						#puts "REDEFINES : #{redefines_ws}"
						stock = ""
					end

				else
					puts "Cas non géré"
				end
				#puts "indicateur : #{val} => #{index}"
			end

			values.each do |c|
				#puts "valeur : #{c}"
				# On stocke le caractère si il est renseigné
				if  (c != " " && c != ".")
					stock << c
				else
					niveau = alim_champs_niveau(stock, niveau_ws)
					if  !niveau.nil?
						niveau_ws = niveau
						#puts "niveau : #{niveau_ws}"
					elsif (variable_ws == "" && stock != "")
						variable_ws = stock
						#puts "variable : #{variable_ws}"
					#else
					#	occurs = alim_champs_occurs(stock, occurs_ws)
					#	if  occurs != ""
					#		ind_occurs = true
					#	elsif ind_occurs == true  && occurs_ws == ""
					#		occurs_ws = stock
					#		puts "occurs : #{occurs_ws}"
					#	else
					#		puts "stock : #{stock}"
					#	end
					end

					if  c == "."
						#ecriture_json_file
						sortie.push(
							{
							    "variable #{i}": {
							        "title": variable_ws,
							        "niveau": niveau_ws,
							        "type": type_ws,
							        "picture": longueur_ws,
									"longueur": "non définie",
							        "compact": comp_ws,
							        "value": value_ws,
							        "thru": thru_ws,
							        "tableau": {
							            "longueur": occurs_ws,
							            "depending_on": depending_ws,
							            "order_type": ordertype_ws,
							            "order_key": order_key_ws,
							            "indexed_by": indexed_ws
							            },
							        "redefines": {
							            "name": redefines_ws
							        }
							    },
							    "commentaire #{i}": commentaire_ws
							}
						)

					end
					#sortie = []
					stock = ""
				end
			end	
		end
		#puts "data : #{sortie}"
		jsonfile = JSON.generate(sortie)
		File.write('sortie.json', jsonfile, mode: 'a')

	end

	def determination_type(picture)
		# suppression des espaces superflus
		# Fragmentation de la donnée numérique pour récupérer le 1er champs
		# Determination du type
		values = picture.strip.split("")
		#puts "picture split : #{values[0]}"
		if  values[0] == "a" || values[0] == "A"
			type = "alphabetic"
		end
		if  values[0] == "X" || values[0] == "x"
			type = "alphanumeric"
		end
		if  values[0] == "9"
			type = "numeric"
		end
		if  values[0] == "S" || values[0] == "s"
			type = "sign"
		end
		return type
	end

	def matching_brackets?(a_string)
		brackets =  {'[' => ']', '{' => '}', '(' => ')'}
		lefts = brackets.keys
		rights = brackets.values
		stack = []
		a_string.each_char do |c|
		  if lefts.include? c
			stack.push c
		  elsif rights.include? c
			stack.push c
		  end
		end
		stack.empty?
	end

	def alim_champs_niveau(data, niv)
		niveau = ["01","02","03","04","05", "07", "10","15","20","25","30","35","40","45","46","47","48","49","66","77","88"]
		result = ""
		# Récupération du niveau si celui ci n'a pas été récupéré
		#puts "niveau-sauv : #{niv}"
		if  data.match(Regexp.union(niveau)) && niv == ""
			result = data
			return result
			#puts "result : #{result}"
		end
		
	end

	def alim_champs_occurs(data, occurs_sauv)
		occurs = ["OCCURS"]
		result = ""
		# Récupération du niveau si celui ci n'a pas été récupéré
		#puts "niveau_sauv : #{niv}"
		if  data.match(Regexp.union(occurs)) && occurs_sauv == ""
			result = data
			return result
			#puts "result : #{result}"
		end
		
	end

	def alim_champs_thru(data)
		thru = ["THRU"]
		result = ""
		# Récupération du niveau si celui ci n'a pas été récupéré
		#puts "niveau_sauv : #{niv}"
		if  data.match(Regexp.union(thru))
			result = data
			return result
			#puts "result : #{result}"
		end
		
	end

	def alim_champs_depending(data)
		depending = ["DEPENDING"]
		result = ""
		# Récupération du niveau si celui ci n'a pas été récupéré
		#puts "niveau_sauv : #{niv}"
		if  data.match(Regexp.union(depending))
			result = data
			return result
			#puts "result : #{result}"
		end
		
	end

	def ctrl_champs(ch1)
		# un numéro de niveau (01 à 49 pour les groupes et leurs éléments), 77 pour les variables isolées, 88 pour les conditions
		ind_type = ind_value = ind_thru = ind_occurs = ind_order = false
		
		type = ["PIC", "PICTURE"]
		valeur = ["VALUE"]
		thru = ["THRU"]
		occurs = ["OCCURS"]
		redefines = ["REDEFINES"]
		comp = ["COMP-1", "COMP-2", "COMP-3", "COMP-4", "COMP-5"]
		order = ["ASCENDING", "DESCENDING"]

		# Positionnement d'un top en fonction des cas rencontrés
		# - Présence d'une picture
		# - Présence de variables conditions (value, thru..)
		# - Présence d'un tableau

		# L'indicateur permet de récupérer le type donnée : Numérique, Alpha etc...
		if  ch1.match(Regexp.union(type))
			ind_type = true
			#puts "type : #{ind_type}"
		end

		# L'indicateur permet de récupérer la valeur du champs
		if  ch1.match(Regexp.union(valeur))
			ind_value = true
			#puts "valeur : #{ind_value}"
		end

		if  ch1.match(Regexp.union(occurs))
			ind_occurs = true
			#puts "occurs : #{ind_occurs}"
		end

		if  ch1.match(Regexp.union(order))
			ind_order = true
			#puts "occurs : #{ind_occurs}"
		end

		if  ch1.match(Regexp.union(redefines))
			ind_redefines = true
			#puts "occurs : #{ind_occurs}"
		end

		return ind_type, ind_value, ind_occurs, ind_order, ind_redefines
	end

	def stats(e1, e2, e3)
		puts "stats"
		all_words = e1.scan(/\w+/)
		word_count = e1.split.length
		good_words = all_words.select{ |word| !e3.include?(word) }
		good_percentage = ((good_words.length.to_f / all_words.length.to_f) * 100).to_i

		#puts "fichier : #{e1}"
		puts ""
		puts "line_count : #{e2}"
		puts "word count : #{word_count}"
		puts "good_percentage : #{good_percentage}"
	end

end

CobolConverter.new.main
