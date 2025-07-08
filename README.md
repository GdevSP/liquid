# Instalando servidor de rádios

Ubuntu LTS (20.04) - Liquidsoap 2.1.3

## Instalar  OPAM

```$ apt-get install libfdk-aac-dev```  
```$ apt-get install opam```  

Crie um novo usuário chamado `radio` para a instalação 

```$ su radio```  
```$ su root -l -c "adduser radio sudo"(se tiver problema com permissão)```  
```$ opam init```  
```$ opam switch create 4.14.0```  
```$ eval $(opam env)```  
```$ ocaml -version```  


## Instalar Liquidsoap

```$ opam install fdkaac```  
```$ opam depext taglib mad lame cry ffmpeg liquidsoap```  
```$ opam install taglib mad lame cry ffmpeg liquidsoap```  
```$ eval $(opam env)```  


## Estrutura de rádios e liquidsoap-daemon
Clone o repo na pasta /home/radio/

```$ git clone https://github.com/savonet/liquidsoap-daemon```  
```$ cd liquidsoap-daemon```  
```$ chmod +x daemonize-liquidsoap.sh```  
```$ ./daemonize-liquidsoap.sh sertaneja```  

Faça o ultimo comando com todas as rádios substituindo o nome

Para comandar a rádio execute como `root`

```$ systemctl (start|stop|restart) sertaneja-liquidsoap```  


## Pedir músicas

Comando apontando para o arquivo de pedido e o caminho da música a ser solicitada.

```$ /home/radio/pedido 8002 "request.push /home/radio/radios/sertaneja/medias/musicas/alan_a_aladim_-_acordei_chorando.mp3"```  

#### Instalar aaPanel
Para funcionar o PM2 mudar versão do NodeJs para 14

#### Instalar id3v2 (apt install id3v2)

#### Gerar arquivo .exe Dart

Dentro da pasta do projeto, execute

```dart compile exe bin/server.dart -o server.exe```  

Desta forma, o arquivo é gerado na pasta de onde o comando é dado.

####Dar permissão 777 para as pastas das rádios 

## NGINX Flutter eb

Adicionar este location nas configurações

```
location / {
      try_files $uri $uri/ /index.html;
}
```
## NGINX proxy reverse para WebSocket

Não utilizar cloudflare no dominio para websocket, ativar Let's Encrypt para SSL

```
location ^~ /
{
      proxy_pass http://127.0.0.1:3000;
      proxy_redirect      off;
      proxy_set_header    Host              $host;
      proxy_set_header    X-Real-IP         $remote_addr;
      proxy_set_header    X-Forwarded-For   $proxy_add_x_forwarded_for;
      proxy_set_header    X-Forwarded-Proto $scheme;

      # WebSocket specific
      proxy_http_version 1.1;
      proxy_set_header   Upgrade $http_upgrade;
      proxy_set_header   Connection "upgrade";
      proxy_read_timeout 600s;
} 
```

## NGINX proxy reverse para shoutcast

Acessar rádios pela porta 80 no formato domain.com/radio/8000

```
# Reverse proxy all possible radio listening ports (8000, 8010...8480, 8490)
location ~ ^/radio/(8[0-4][0-9]0)(/?)(.*)$ {

        resolver 127.0.0.1;

        proxy_buffering           off;
        proxy_ignore_client_abort off;
        proxy_intercept_errors    on;
        proxy_next_upstream       error timeout invalid_header;
        proxy_redirect            off;
        proxy_connect_timeout     60;
        proxy_send_timeout        21600;
        proxy_read_timeout        21600;

        proxy_set_header Host localhost:$1;        
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Real-IP $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

        proxy_pass http://127.0.0.1:$1/$3?$args;       
}
```
