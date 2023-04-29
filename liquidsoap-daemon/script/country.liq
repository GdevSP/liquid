#!/usr/bin/liquidsoap
######################################### CONFIGURAÇÕES ###################################################
set("server.telnet", true)
set("server.telnet.port", 8112)
set("harbor.bind_addrs",["0.0.0.0"])
set("log.stdout", true)
set("log.file", true)
set("server.telnet.bind_addr","127.0.0.1")
set("tag.encodings",["UTF-8","ISO-8859-1"])
setenv("TZ", "America/Sao_Paulo")
log.file.path.set("/tmp/basic-radio.log")


######################################### PASTAS DE MÍDIAS #################################################

musicas = playlist(mode="random",reload_mode="watch", "/home/radio/radios/country/medias/musicas")
agendamento = playlist(mode="random",reload_mode="watch", "/home/radio/radios/country/medias/agendamento")
cada_duas_horas = playlist(mode="normal", reload_mode="watch", "/home/radios/radio/country/medias/cada_duas_horas")
cada_hora = playlist(mode="normal", reload_mode="watch", "/home/radio/radios/country/medias/cada_uma_hora")
vinhetas = playlist(mode="normal", reload_mode="watch", "/home/radio/radios/country/medias/vinhetas")
erro = single("/home/radio/erro.mp3")

##############################################################################################################

radio = fallback([request.queue(id="request"), musicas])

radio = fallback([switch([({(6w or 7w) and 22h00-23h59},  agendamento)]), radio])

radio = fallback([delay(600., vinhetas), radio])

def predicate.activates(~init=false, p)
  last = ref(not init)
  fun () -> begin
    cur = p()
    ans = (not !last) and cur
    last := cur
    ans
  end
end

radio = fallback([switch([(predicate.activates({ 0m-10m }), cada_hora)]), radio])
radio = fallback([delay(7200., cada_duas_horas), radio])

live = input.harbor("/", port = 8114, password = "mgt6anos", icy = true, 
icy_metadata_charset = "UTF-8", metadata_charset = "UTF-8",buffer = 5., max = 10.)
radio = fallback(track_sensitive=false, [live, radio, erro])


############################# CONTROLE DE GANHO AUTOMÁTICO ###############################################################

radio = crossfade (duration=4.,fade_in=0.1,fade_out=0.1,radio)
radio = normalize(target = 0., window = 0.03, gain_min = -16., gain_max = 0., radio)
radio = compress.exponential(radio, mu = 1.0)

######################################### SAÍDAS DO ÁUDIO #################################################################

def apply_metadata(m) =
  title = m["title"]
  artist = m["artist"]
  track = m["tracknumber"]
  upo = process.read.lines('curl -X POST -H "Content-Type: multipart/form-data"  -F "title=#{title}" -F "artist=#{artist}" -F "music_id=#{track}" -F "name=MGT COUNTRY" -F "style=Música Country" -F "id=country" https://api.mgtradio.net/ws/metadata/update')
  log("Tocando agora: #{title} by #{artist} recebeu do servidor #{upo}")
  [("title",title), ("artist",artist)]
end

radio = map_metadata(apply_metadata,radio)

######################################### SAÍDAS DO STREAM #################################################################

output.shoutcast( 
	fallible=true,   
    %fdkaac(channels=2, samplerate=44100, bitrate=64, afterburner=false, aot="mpeg4_he_aac_v2", sbr_mode=true),	
	host="localhost", port = 8110,
	password = "neZNk22W:#1",
	icy_id = 1, 
	name = "MGT Country", 
	genre = "Country", 
	url = "https://www.mgtradio.net/country", 
	public = true, 
	encoding = "UTF-8", 			
	radio
)

