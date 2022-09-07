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
![commit](https://raw.githubusercontent.com/pero85v/stakewars-iii/main/images/commit.jpg)
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
На скриншоте видно что начали закачиваться заголовки, дальше закачиваются блоки, полная синхронизация может занять много времени.

Активирую ноду, чтобы ее можно было использовать как валидатора. Сначала авторизую кошелек локально:
```
near login
```
Получаю ссылку: https://wallet.shardnet.near.org/login/?referrer=NEAR+CLI&public_key=ed25519%3ABueXu2w6XcVjJxp6BGw7b4cFBUE9iwZZNi57g1Eov1WB&success_url=http%3A%2F%2F127.0.0.1%3A5000

Открываю ссылку в браузере, где мой кошелек. Подтверждаю доступ. В финале когда появляется ошибка страницы, возвращаюсь обратно к серверу. И ввожу название своего кошелька: **roltop.shardnet.near**

Теперь создам файл **validator_key.json** с помощью команды, где **test-split-pool** вы должны заменить на вами придуманное название валидатора:
```
near generate-key test-split-pool.factory.shardnet.near
```
Копирую и перименовываю файл:
```
cp $HOME/.near-credentials/shardnet/test-split-pool.factory.shardnet.near.json $HOME/.near/validator_key.json
```
Внесу  исправления в файл, заменю слово **private_key** на **secret_key**:
```
vi $HOME/.near/validator_key.json
```
**validator_key.json** должен содержать (свои ключи я закрыл символами XXXXX) следующее:
```
{"account_id":"test-split-pool.factory.shardnet.near","public_key":"ed25519:XXXXX","secret_key":"ed25519:XXXXX"}
```
**validator_key.json** это файл в котором записаны открытый и закрытый ключи валидатора, поэтому необходимо его забэкапить.

Для того чтобы не держать сессию putty всегда открытой, настрою запуск ноды в виде демона. Создаю файл:
```
sudo vi /etc/systemd/system/neard.service
```

Записываю в файл следующее содержимое:
```
[Unit]
Description=NEARd Daemon Service

[Service]
Type=simple
User=<USER>
#Group=near
WorkingDirectory=/home/<USER>/.near
ExecStart=/home/<USER>/nearcore/target/release/neard run
Restart=on-failure
RestartSec=30
KillSignal=SIGINT
TimeoutStopSec=45
KillMode=mixed

[Install]
WantedBy=multi-user.target
```
Замените **<USER>** на свой логин на сервере.

Активирую следующей командой:
```
sudo systemctl enable neard
```

Запуск:
```
sudo systemctl start neard
```
Остановка:
```
sudo systemctl stop neard
```
Перезапуск:
```
sudo systemctl reload neard
```

Запускаю свою ноду и оставляю ее синхронизироваться.

Посмотреть логи:
```
journalctl -n 100 -f -u neard
```

Для того чтобы сделать вывод логов более комфортным, установлю:
```
sudo apt install ccze
```
Теперь команда для просмотра выглядит так:
```
journalctl -n 100 -f -u neard | ccze -A
```

**Пожалуйста обратите внимание**, для валидации, надо выполнять условия:
Полностью синхронизировать ноду. Создать и разместить файл **validator_key.json**. При создании пула валидатора должен быть использовано значение поля **public_key** начинающееся с **ed25519**: из файла **validator_key.json**. Сумма застейканых токенов должна быть больше стоимости места. **Proposal** должно быть отправлен путем функции ping. Валидатор начинает валидировать после двух-трех эпох, после того как пройдет его **proposal**. Валидатор должен производить более 90% назначенных блоков, иначе будет выброшен из валидации на следующую эпоху.

Создам пул ставок:
```
near call factory.shardnet.near create_staking_pool '{"staking_pool_id": "<pool name>", "owner_id": "<accountId>", "stake_public_key": "<public key>", "reward_fee_fraction": {"numerator": 5, "denominator": 100}, "code_hash":"DD428g9eqLL8fWUxv8QSpVFzyHi1Qd16P8ephYCTmMSZ"}' --accountId="<accountId>" --amount=30 —gas=300000000000000
```

С моими параметрами команда выглядит так:
```
near call factory.shardnet.near create_staking_pool '{"staking_pool_id": "test-split-pool", "owner_id": "roltop.shardnet.near", "stake_public_key": "ed25519:DG5tyg5Q32zSaMeyEZpK9njDqMWTN9o3BL3fv3wAohFU", "reward_fee_fraction": {"numerator": 10, "denominator": 100}, "code_hash":"DD428g9eqLL8fWUxv8QSpVFzyHi1Qd16P8ephYCTmMSZ"}' --accountId="roltop.shardnet.near" --amount=30 —gas=300000000000000
```
**test-split-pool** это часть названия моего пула ставок.
К пулу ставок потом можно будет обращаться так: **test-split-pool.factory.shardnet.near**
**roltop.shardnet.near** мой кошелек. 
значение начинающееся с **ed25519:** берем из поля **public_key** файла **validator_key.json**
здесь **10** это процент который пул ставок будет брать со всех делегаций, тоесть **{"numerator": 10, "denominator": 100}** это **10** процентов комиссии.
Этой командой я создал пул  **test-split-pool.factory.shardnet.near**
![create_staking_pool](https://raw.githubusercontent.com/pero85v/stakewars-iii/main/images/deploy.jpg)

Внесу тестовые токены на контракт пула ставок и застейкаю их одной командой:
```
near call test-split-pool.factory.shardnet.near deposit_and_stake --amount 10 --accountId roltop.shardnet.near —gas=300000000000000
```

Вывести из стейка 10 тестовых токенов, следующая команда:
```
near call test-split-pool.factory.shardnet.near unstake '{"amount": "10000000000000000000000000"}' --accountId roltop.shardnet.near--gas=300000000000000
```

Для начала валидации и каждую эпоху надо использовать команду **ping**. Надо использовать скрипты и крон чтобы **ping** выполнять автоматически. Если прервалась валидация, для входа в валидацию тоже надо использовать **ping**:
```
near call test-split-pool.factory.shardnet.near ping '{}' --accountId roltop.shardnet.near --gas=300000000000000
```

Данные команды NEAR-CLI позволяют видеть валидирует ли ваша нода в текущую эпоху, следующую и принято ли предложение на валидацию.
Показывает принятые предложения в набор валидаторов:
```
near proposals
```
Список активных валидаторов в текущую эпоху:
```
near validators current
```
Список валидаторов которые будут валидировать в следующую эпоху:
```
near validators next
```

Контроль логов позволяет мониторить ноду. Также надо настроить извещения приходящие на почту или в телеграм о работе ноды.
![Лог ноды валидатора](https://raw.githubusercontent.com/pero85v/stakewars-iii/main/images/sync_val.jpg)
**#3344617** номер текущего блока
**Validator** появляется когда нода валидирует
**100 validators** 100 валидаторов блоков (валидаторы чанков считаются отдельно)
**35 peers** к моей ноде сейчас подключено 35 пиров, чтобы достичь консенсуса и начать валидацию нужно как минимум 3 пира.

Также для получения информацию о состоянии ноды, процессе валидаци используется RPC. Но также можно использовать для взаимодействия с блокчейном, акаунтами и контрактами.

Нужно установить пакеты:
```
sudo apt install curl jq
```

Теперь я могу увидеть свою версию ноды:
```
curl -s http://127.0.0.1:3030/status | jq .version
```

В случае проблем, могу посмотреть причину почему был выброшен из валидации:
```
curl -s -d '{"jsonrpc": "2.0", "method": "validators", "id": "dontcare", "params": [null]}' -H 'Content-Type: application/json' 127.0.0.1:3030 | jq -c '.result.prev_epoch_kickout[] | select(.account_id | contains ("test-split-pool.factory.shardnet.near"))' | jq .reason
```

Могу посмотреть количество блоков и чанков произведенных и ожидаемых:
```
curl -r -s -d '{"jsonrpc": "2.0", "method": "validators", "id": "dontcare", "params": [null]}' -H 'Content-Type: application/json' 127.0.0.1:3030 | jq -c '.result.current_validators[] | select(.account_id | contains ("test-split-pool.factory.shardnet.near"))'
```

Чтобы получить информацию о делегациях и стейках, можно использовать NEAR-CLI:
```
near view test-split-pool.factory.shardnet.near get_accounts '{"from_index": 0, "limit": 10}'
```

Дополнительные способы контроля и мониторинга приветствуются.
