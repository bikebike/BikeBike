#require 'sorcery/lib/sorcery/crypto_providers/common'
#require 'ruby_drupal_hash'

module Sorcery
	module CryptoProviders
		class DrupalPassword # < Sorcery::CryptoProviders::Common
			include Common
			class << self
				#def join_token
				#	@join_token ||= "--"
				#end
				
				# Turns your raw password into a Sha1 hash.
				def encrypt(*tokens)
					#puts tokens
					#x
					#tokens = tokens.flatten
					#digest = tokens.shift
					#stretches.times { digest = secure_digest([digest, *tokens].join(join_token)) }
					#digest
					hash(tokens.first())
				end
				
				#def secure_digest(digest)
				#	#Digest::SHA1.hexdigest(digest)
				#	hash(digest)
				#end

				DRUPAL_MIN_HASH_COUNT = 7
				DRUPAL_MAX_HASH_COUNT = 30
				DRUPAL_HASH_LENGTH = 55
				ITOA64 = './0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'

				HASH = Digest::SHA2.new(512)

				def hash(password)
					return false if password.nil?

					setting = '$S$DXHwLLD9k'

					count_log2 = ITOA64.index(setting[3])

					if count_log2 < DRUPAL_MIN_HASH_COUNT or count_log2 > DRUPAL_MAX_HASH_COUNT
						return false
					end

					salt = setting[4..4+7]

					if salt.length != 8
						return false
					end

					count = 2 ** count_log2

					pass_hash = HASH.digest(salt + password)

					1.upto(count) do |i|
						pass_hash = HASH.digest(pass_hash + password)
					end

					hash_length = pass_hash.length

					output = setting + _password_base64_encode(pass_hash, hash_length)

					if output.length != 98
						return false
					end

					return output[0..(DRUPAL_HASH_LENGTH - 1)]
				end

				def _password_base64_encode(to_encode, count)
					output = ''
					i = 0
					while true
						value = (to_encode[i]).ord

						i += 1

						output = output + ITOA64[value & 0x3f]
						if i < count
							value |= (to_encode[i].ord) << 8
						end

						output = output + ITOA64[(value >> 6) & 0x3f]

						if i >= count
							break
						end

						i += 1

						if i < count
							value |= (to_encode[i].ord) << 16
						end

						output = output + ITOA64[(value >> 12) & 0x3f]

						if i >= count
							break
						end

						i += 1

						output = output + ITOA64[(value >> 18) & 0x3f]

						if i >= count
							break
						end

					end
					puts "\nHASH:\t#{output}\n"
					return output
				end
			end
		end
	end
end
