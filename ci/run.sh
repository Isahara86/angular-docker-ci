#mainFileName="$(ls /usr/share/nginx/html/main-es5.*.js)"
#envsubst '$BACKEND_API_URL $DEFAULT_LANGUAGE ' <${mainFileName} >main.tmp
#mv main.tmp ${mainFileName}
#mainFileName="$(ls /usr/share/nginx/html/main-es2015.*.js)"
#envsubst '$BACKEND_API_URL $DEFAULT_LANGUAGE ' <${mainFileName} >main.tmp
#mv main.tmp ${mainFileName}

for i in /usr/share/nginx/html/main*.js; do
    [ -f "$i" ] || break
    mainFileName="$i"
    envsubst '$BACKEND_API_URL $DEFAULT_LANGUAGE ' <${mainFileName} >main.tmp
    mv main.tmp ${mainFileName}
done
nginx -g 'daemon off;'
