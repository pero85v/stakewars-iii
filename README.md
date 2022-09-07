# Stake Wars: Episode III. Challenge 005

Здесь подбробно разъясняется как установливать ноду для своего валидатора Near в тестовой сети shardnet.

Системные требования:
CPU 8-Core CPU with AVX support
RAM >16GB DDR4 (recommended is 20+ GB)
Storage 500GB SSD
Также надо открыть порты:
p2p	24567/tcp
RPC	3030/tcp

Я буду пользоваться услугами облачного провайдера: https://www.hetzner.com/ru/cloud?country=ru
Для тестирования нам подойдет вариант CCX31 или CCX32 с выделенными vCPU:
vCPU 8 Intel, AMD
RAM 32 GB
Диск 240 GB 
Операционную система Ubuntu
Выделенные vCPU нужны потому, что есть нюанс. Если мощности процессора не хватит, ваша нода на начальном этапе прекратит синхронизацию и вы не сможете догнать актуальную высоту блоков. Объема SSD 240 GB должно хватить, на данный момент блокчейн тестовой сети shardnet занимает не больше 200GB. Цена за месяц большая, но чтобы провести тестирование вам достаточно будет недели, так что обойдется дешевле. Если вы планируете использовать полмесяца и больше, то предлагаю вам обратить внимание на выделенные сервера.

Я создам свой аккаунт с тестовыми токенами, пройдя по ссылке: https://wallet.shardnet.near.org/
Обязательно сохраните мнемонику(набор слов) которые вам выдадут.

После заказа сервера, вам на почту прийдет письмо с IP адресом и логином-паролем. Первоначальные действия я опущу, такие как подключение с помощью putty к серверу, создание своего пользователя и настройки безопасности, таких статей много в интернете.

Приступим к настройке.

Данной командой я обновлю пакеты на сервере:
```
sudo apt update && sudo apt upgrade -y
```

Устанавливаю Node.js и npm:
```
curl -sL https://deb.nodesource.com/setup_18.x | sudo -E bash -  
sudo apt install build-essential nodejs
PATH="$PATH"
```

Версии должны быть не меньше:
```
node -v
v18.x.x
npm -v
8.x.x
```

Устанавливаю NEAR-CLI, с помощью этой утилиты происходит взаимодействие с блокчейном Near, можно посмотреть состояние аккаунта, отправить транзакции и т.д. и т.п.:
```
sudo npm install -g near-cli
```

Эта переменная нужна чтобы работать именно с тестовой сетью Shardnet. Я также её сохраняю чтобы не повторять ввод в дальнейшем:
```
export NEAR_ENV=shardnet
echo 'export NEAR_ENV=shardnet' >> ~/.bashrc
echo 'export NEAR_ENV=shardnet' >> ~/.bash_profile
source $HOME/.bash_profile
```

Доступные команды NEAR-CLI можно проверить так:
```
near --help
```

С помощью этой команды я проверяю поддерживает ли мой процессор функции неодходимые для ПО neard:
```
lscpu | grep -P '(?=.*avx )(?=.*sse4.2 )(?=.*cx16 )(?=.*popcnt )' > /dev/null \
  && echo "Supported" \
  || echo "Not supported"
```

Если ответ будет **Supported**, тогда в бой!

Ноду буду компилировать из исходников. Устанавливаю следующие пакеты:
```
sudo apt install -y git binutils-dev libcurl4-openssl-dev zlib1g-dev libdw-dev libiberty-dev cmake gcc g++ python3 docker-ce docker.io protobuf-compiler libssl-dev pkg-config clang llvm cargo make
```

Устанавливаю питоновскую систему управления пакетами:
```
sudo apt install python3-pip
```

Сохраняю переменные:
```
USER_BASE_BIN=$(python3 -m site --user-base)/bin
export PATH="$USER_BASE_BIN:$PATH"
```

Устанавливаю Rust и Cargo:
```
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```
После запуска подтверждаю первый пункт по умолчанию нажимая Enter или надо нажать **1** и **Enter**.

Получаю переменные окружения для Cargo. Если в дальнейшем необходимо будет скомпилировать новую версию neard, то этот пункт лучше повторить:
```
source $HOME/.cargo/env
```

Клонируем проект nearcore с GitHub:
```
cd $HOME
git clone https://github.com/near/nearcore
cd $HOME/nearcore
git fetch
```

Актуальный коммит беру отюда: https://github.com/near/stakewars-iii/blob/main/commit.md 
На данный момент это **1897d5144a7068e4c0d5764d8c9180563db2fe43**
```
git checkout 1897d5144a7068e4c0d5764d8c9180563db2fe43
```

Комплирую nearcore (в зависимости от сервера, это может быть очень долго):
```
cargo build -p neard --release --features shardnet
```

Если процесс компиляции прошел без ошибок, то запускающий файл будет находиться здесь:
```
cd $HOME/nearcore
./target/release/neard
```

Сформирую необходимые файлы для старта ноды:
```
cd $HOME/nearcore
./target/release/neard --home $HOME/.near init --chain-id shardnet --download-genesis
```

В папке **$HOME/.near** были созданы файлы **config.json**, **node_key.json** и **genesis.json**

Удаляю config.json и закачиваю актуальный:
```
rm $HOME/.near/config.json
wget -O $HOME/.near/config.json https://s3-us-west-1.amazonaws.com/build.nearprotocol.com/nearcore-deploy/shardnet/config.json
```

Запускаю ноду:
```
cd $HOME/nearcore
./target/release/neard --home ~/.near run
```
![синхронизация](https://raw.githubusercontent.com/pero85v/stakewars-iii/main/images/syncing.jpg)
