# Ansible勉強会

# 概要

## 勉強会をした理由

- デジ共では、そもそもAnsibleのコードレビューを行っていない。。
- なんとなくハードルが高い

> Ansibleが、なんとなく何をやっているのか理解できるようになる
> 

## Ansibleとは

・作業手順書をコード化し、実行させるツール
・冪等性を担保し、何度実行しても同じ結果を得られる

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/2c316c37-8f95-4537-bb72-91cc14d19ae2/e1948201-61d5-4143-aef2-0e5b743056cf/Untitled.png)

## 冪等性とは

「**ある操作を1回行っても複数回行っても結果(状態)が同じになる性質**」

Playbookは何度実行しても、同じ実行結果になる。

例えば、Nginxをインストールするスクリプトを書く場合に、
シェルスクリプトの場合は、対象サーバにnginxがインストールされてるかなどを条件分岐するなどの工夫が必要あるのに対し、
Ansibleでは、そういった処理がモジュール化されていて、対象がnginx、バージョンがXXと指定すれば、あとはAnsibleにお任せできる。
なので、複雑な条件分岐を高度なプログラミング能力不要で、冪等性を担保できる。

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/2c316c37-8f95-4537-bb72-91cc14d19ae2/1e84a275-a8d0-43d2-8ac1-fef733441101/Untitled.png)

<aside>
💡 注意点
実際のプロジェクトでは、複数のPlaybpookが実行されるため、他Playbpookの実行によって、他のPlaybpookの想定の結果と異なってしまうことがあり、
その結果、冪等性が失われることがあるため、そこがレビュワーの視点になる。
例）Playbook Aで有効化にしているものが、Playbook Bで無効化になっていたなど

</aside>

## 他の構成管理ツールとの違い

他の構成管理ツールではなく、Ansibleを利用する理由として、下記２点がある

- エージェントレス

他の構成管理ツールは、対象デバイスにエージェントをインストールする必要があるが、
Ansibleは、各サーバーのansible用ユーザにSSHして変更するためエージェントのインストールが不要。

<aside>
💡 エージェント型は、エージェントのバージョン管理やCPU使用率の高騰など管理しないといけない項目が増えてしまう。

</aside>

- 記述方式

YAMLなので、プログラミング知識や独自言語を覚える必要がない。

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/2c316c37-8f95-4537-bb72-91cc14d19ae2/52f16a37-dc74-48e4-a793-5adbc85f4e99/Untitled.png)

| 比較項目 | Ansible | Puppet | Chef |
| --- | --- | --- | --- |
| 開発組織 | RedHat | Puppet Labs | Chef Software |
| 使用言語 | Python | Ruby | Ruby |
| アーキテクチャ | エージェントレス(SSH方式) | エージェント | エージェント |
| 構成管理方法 | Push型通信 | Pull型通信 | Pull型通信 |
| 制御ファイル | playbook | manifest | Recipe |
| コード記述言語 | YAML | 独自言語 | Ruby |
| 使用プロトコル | SSH/NETCONF | HTTP/HTTPS | HTTP/HTTPS |

# 本編

## 全体図

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/2c316c37-8f95-4537-bb72-91cc14d19ae2/5568d73f-373b-4029-9f96-dca936072695/Untitled.png)

| ansible.cfg
(Ansible Configuration Settings) | Ansibleの設定ファイルで、ログの出力先や接続後のユーザーなど、
共通で利用する設定を行うファイル |
| --- | --- |
| Inventory(インベントリー) | ・操作対象とするホストのアドレスを記述し、管理対象を定義するファイル
 ・デフォルトファイルは/etc/ansible/hosts　※ansible.cfgで指定可能 |
| Variables(var) | Ansibleで利用する変数を定義するファイル
・Playbookやロールの中で使用される値をまとめたファイル
・Host毎や各Role毎でも作成可能 |
| Playbook | ・リモートホストの状態を定義したファイル
 ・各要素を複数組み合わせ、管理対象の設計書の役割 |
| Roles/Task(Tasks lists) | 具体的な処理を記載したファイル |

## インベントリー

操作対象とするホストのアドレスを記述し、管理対象を定義する役割

### ファイル形式

- INI形式(一般的にはこっち)
- YAML形式

### デフォルトインベントリ

- デフォルト

/etc/ansible/host
※ansible.cfgで指定可能

- カスタマイズ

playbook実行時に ansible-playbook -i <インベントリファイルのパス>で指定する

### 記載例(ini形式)

管理したいサーバーをIPアドレスやホスト名(hostsファイル等で定義さえている場合)で記載する。

また、ホストの役割毎にグルーピングすることで、グループ指定でもPlaybookを実行できる。

```yaml
# [グループ名]で記載することで、グルーピングできる
[web_server]  
#グループに追加するホストのIPアドレスを追加
192.18.176.216 

##グループ名
[oracle] 
#IPではなく、ホスト名でも可
oracle_01 
oracle_02

[mysql] 
#IPではなく、ホスト名でも可
mysql_01 
mysql_02

#さらに、上の階層でグループ化もできる
#書き方は[グループ名:children]
[db_server:children]
oracle
mysql
```

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/2c316c37-8f95-4537-bb72-91cc14d19ae2/f04d448b-ebcb-43c9-9bcd-b91794e1c21b/Untitled.png)

## Varsファイル（変数定義）

### インベントリファイルに設定する場合

```bash
~~~
##グループ名
[oracle] 
#　ホスト変数
#　ターゲットホスト限定で変数を指定する場合、ホスト名の後ろに定義できる
# 例）ansible_host=<IPアドレス> 
oracle01 ansible_host=10.16.10.11 
oracle02 ansible_host=10.16.10.12

[mysql] 
#IPではなく、ホスト名でも可
mysql_01 
mysql_02

#さらに、上の階層でグループ化もできる
[db_server:children]
oracle
mysql

[db_server:vars]
# グループ変数
# グループ全体に適用する変数も設定できる
# 例）ansible_user=<使用するユーザ名>
ansible_user=user01

```

参考：https://docs.ansible.com/ansible/2.9_ja/reference_appendices/special_variables.html

### Varファイルを作る場合

上記は、変数定義をインベントリファイルに直接記載してきたが、ホスト毎、グループ毎にVars(変数定義)ファイルを分けることもできる。

### 配置先

- グループ変数

group_varsディレクトリ配下にyml形式で定義する

<aside>
💡 一般的には<グループ名>.ymlで命名する

</aside>

- ホスト変数
    
    host_varsディレクトリ配下にyml形式で定義する
    

```bash
├── group_vars
│   ├── all.yml
│   └── db_server.yml
│   └── web_sever.yml
├── host_vars
│   ├── 192.18.176.216.yml
│   ├── mysql01.yml
│   ├── mysql02.yml
│   ├── oracle01.yml
│   ├── oracle02.yml
└── inventory.ini
```

## プレイブック

まず、Playbookは大きく４セクションに分かれて記述します

- Targetセクション

Targetホストの指定(hosts)を行うセクション。

指定したinventoryの中で、実行するホストを指定できる(省略可)

- Varsセクション

Playbookのなかで利用したい変数を定義するセクション

- Task(role)セクション

処理内容を記載するセクション

- Handlersセクション

実行制御処理を記載するセクション

<aside>
💡 hanndlerとは、要求が発生した時にプログラム処理を中断して呼び出される関数などのことをいう。

</aside>

Target~handlerまでの処理の流れをplayといいます。
playbookは、このplayの集合体でできている。

### 実際に書いてみる

まず、手作業でNginxをインストールする場合、下記手順になると思います。

1. 対象サーバーにログインする
2. rootにスイッチする
3. yumでNginxをインストールする
4. nginx.confを編集する
5. Nginxを再起動する

これを実際にNginxをインストールするPlaybookを作成していきます。

> 対象サーバーにログインする
> 

---Targetセクション---

対象サーバーはTargetセクションで指定します。

今回は、`web_sever`グループを対象とすると、`- hosts: web_sever` になります。

```bash
- hosts: web_sever
```

> rootにスイッチする
> 

---Varsセクション---

rootで作業をするには、Varsセクションで`become = True`と設定します。

```bash
  vars: 
    become = True
```

> yumでNginxをインストールする
> 

 ---Task(role)セクション---

yumでパッケージをインストールする場合は、yumモジュールを利用します。

```bash
    - name: install nginx 
	    yum: 
        name: nginx
        state: present
```

> nginx.confを編集する
> 

 ---Task(role)セクション---

nginx.confを編集するには、２つ方法があります。

１つ目は、テキスト編集のモジュールで行数を指定して置換する方法です。
しかし、この方法だと、誤った行を編集してしまうリスクがあるので、ファイルの行数などを完璧に把握する必要があり、非推奨な方法になります。
２つ目は、事前にファイルを用意しておき、上書きをする方法です。
一般的には、こちらのやり方で実施します。
用意したファイルを配布するには、copyモジュールを利用します。
copyモジュールでは、src(配布対象のファイルパス)とdest(配布先のファイルパス)を指定し、ownerとgroupにファイル権限を変更することができます。

```bash
    - name: copy nginx conf
      copy:
        src: "roles/install_nginx/files/nginx.conf"
        dest: "/etc/nginx/nginx.conf"
        owner: root
        group: root
```

> Nginxを再起動する
> 

  ---Handlersセクション---

ここまでで、Nginxのインストール、confファイルの編集が完了したので、再起動を行います。
再起動は、systemdモジュールを利用します。
systemdモジュールでは、nameに指定したパッケージに対して、stateで指定した状態にします。
今回は、nginxを再起動なので、下記のようになります。

```bash
 - name: restart nginx
      systemd: name=nginx state=restarted
```

しかし、nginxの再起動のように複数回実行する可能性の高いものは、taskセクションではなく、
Handlersセクションに記載し、必要に応じて呼びだすことが一般的です。
この場合、Handlersセクションに、上記のタスクを記載し、
呼びさしたいtaskの最後にnotifyモジュールを使い呼び出します。

```bash
    - name: copy nginx conf
      copy:
        src: "files/nginx.conf"
        dest: "/etc/nginx/nginx.conf"
        backup: no
        owner: root
        group: root
      notify: restart nginx
      
  ---Handlersセクション---
  handlers:
    - name: restart nginx
      systemd: name=nginx state=restarted
```

これで完成です。

```bash
~/ansible $ ll

-rw-r--r--  1 nhasumi nhasumi  306 Jan 24 12:22 ansible.cfg
-rw-r--r--  1 nhasumi nhasumi  136 Jan 23 19:21 install_nginx.yml
drwxr-xr-x  4 nhasumi nhasumi 4096 Jan 21 00:01 inventories/
drwxr-xr-x  5 nhasumi nhasumi 4096 Jan 23 18:44 files/
```

```bash
---Targetセクション---
- hosts: all

---Varsセクション---
  vars: 
    become = True
	  
 ---Task(role)セクション---
  tasks:
    - name: install nginx 
	    yum: 
        name: nginx
        state: present
      
    - name: copy nginx conf
      copy:
        src: "roles/install_nginx/files/nginx.conf"
        dest: "/etc/nginx/nginx.conf"
        backup: no
        owner: root
        group: root
      notify: restart nginx
      
  ---Handlersセクション---
  handlers:
    - name: restart nginx
      systemd: name=nginx state=restarted
```

### ロール

上記で、Nginxのインストールを行う単純なPlaybookだったが、実際には一つのPlaybookの中で複数のPlayが実行される。
しかし、複数ののPlaybookで記載すると、管理が煩雑になり、運用が難しくなる。

そこで、各playごとにフォルダを分割することができます。

これをroleといいます。
rolesでは、ansibleディレクトリ配下にrolesというディレクトリを作り、その配下にinstall_nginxやinstall_mysqlのようにPlay毎(役割毎)分けます。

例えば、上記のinstall_nginx.ymlを分割すると、下記になる。

```bash
../roles/install_nginx
├── files
│   ├── nginx.conf
├── vars
│   └── main.yml
├── handlers
│   └── main.yml
└── tasks
    └── main.yml
```

rolesの配下にinstall_nginxというディレクトリを作成し、さらにセクションごとでフォルダ分けします。
各セクションのmain.ymlに記載する内容は変わらない。

フォルダ構成

```bash
├── ansible.cfg
├── install_nginx_playbook.yml
├── inventories
│   ├── group_vars
│   │　├── all.yml
│   │　└── db_server.yml
│   │　└── web_sever.yml
│　 ├── host_vars
│   │　├── 192.18.176.216.yml
│   │　├── mysql01.yml
│   │　├── mysql02.yml
│   │　├── oracle01.yml
│   │　└── oracle02.yml
│   └── inventory.ini
└── roles
    ├── files
    │   ├── nginx.conf
    ├── vars
    │   └── main.yml
    ├── handlers
    │   └── main.yml
    └── tasks
        └── main.yml
```

tasks/main.yml

```bash
    - name: install nginx 
	    yum: 
        name: nginx
        state: present
      
    - name: copy nginx conf
      copy:
        src: "roles/install_nginx/files/nginx.conf"
        dest: "/etc/nginx/nginx.conf"
        backup: no
        owner: root
        group: root
      notify: restart nginx
```

install_nginx_playbook.yml

```bash
- hosts: web_sever
  roles:
  - install_playbook
```

# おまけ

よく使われるモジュール