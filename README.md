# simdis_openresty
基于openresty的简单分发

--安装

./configure --prefix=/usr/local/openresty --with-pcre=pcre-8.36/ --without-select_module --without-poll_module --with-http_gzip_static_module --with-http_ssl_module --with-http_gunzip_module --with-http_stub_status_module  --with-file-aio --with-luajit
gamek
gmake install
