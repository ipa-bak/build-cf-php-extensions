#! /bin/bash

php_bp="${BUILDPACK:-}"

if [ -n "${1:-}" ] ; then
    php_bp="$1"
fi

if [ -z "{php_bp}" ] ; then
    echo "need URL for build pack"
    exit 1
fi

set -e
set -x

pushd /tmp/input
php_bp_name="${php_bp##*/}"
if [ ! -e ${php_bp_name} ] ; then
    wget "${php_bp}"
fi
mkdir -pv php_bp
cd php_bp
unzip  "../${php_bp_name}"
php_version_list_url=($(grep -e 'https://buildpacks.cloudfoundry.org/.*/php/.*.tgz' manifest.yml | cut -d : -f 2-))
popd

num_jobs=$(grep -e processor /proc/cpuinfo | wc -l)

echo "${php_version_list_url[@]}"

function do_version() {
    local bp_php_url="$1"
    local version="$2"
    local version_git="${version//_/.}"
    local version_x="${version_git%.*}.x"
    local base="/tmp/input"
    local bp_files="${base}/php_bp"
    local bp_php_files="${base}/bp_${version}"
    local bp_php_bin="${bp_php_files}/bin"
    local bp_php_tgz="${base}/${bp_php_url##*/}"

    mkdir -pv "${bp_php_bin}"
    pushd "${base}"
    test -e "${bp_php_tgz}" || wget "${bp_php_url}"
    popd

    pushd "${bp_php_files}"
    tar -xpzf "${bp_php_tgz}"
    popd

    pushd /tmp/input/php-src
    git checkout -f "php-${version_git}"

    local configure_line=($(${bp_php_bin}/php -r 'phpinfo();' | grep -e configure | cut -d '>' -f 2-))
    local prefix="$(echo "${configure_line[@]}" | \
      sed -E -e 's/.*--prefix=([^'"'"']+).*/\1/' )"

    git clean -fdx
    rm -rf "${prefix:-/tmp/no-dir}"
    ./buildconf --force
    eval "${configure_line[@]}"
    make -j${num_jobs} LDFLAGS="-lz"
    make install

    local ext_dir=${prefix}/lib/php/extensions/no-debug-non-zts-*
    rm -rf /home/vcap/app || true
    mkdir -pv /home/vcap/app/{php,lib,tmp}

    sed -E -e 's%@\{HOME\}%/home/vcap/app%g; s%#\{LIBDIR\}%lib%g; s%@\{TMPDIR\}%/home/vcap/tmp%g' <${bp_files}/defaults/config/php/${version_x}/php.ini >${prefix}/etc/php.ini
    pecl config-set ext_dir ${ext_dir}
    pecl config-set php_ini ${prefix}/etc/php.ini 
    pecl config-set bin_dir ${prefix}/bin
    pecl config-set php_bin ${prefix}/bin/php

    local old_PATH="$PATH"
    export PATH=${prefix}/bin:${prefix}/sbin:$PATH
    pecl uninstall -r mongodb || true
    pecl install mongodb-1.8.1 || pecl install -s "http://pecl.php.net/get/mongodb-1.8.1.tar"
    export PATH="${old_PATH}"

    cp -pv ${ext_dir}/mongodb.so /root/mongodb_${version}.so

}

for i in "${php_version_list_url[@]}" ; do
    i2="${i##*php?_}"
    i2=(${i2%%_linux*})
    do_version "${i}" "$i2" || true
done

