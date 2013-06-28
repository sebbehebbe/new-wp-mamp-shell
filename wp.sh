#!/bin/sh
cd /Applications/MAMP/htdocs

# Welcome Message
printf "Hi friends! Let's create a new Wordpress installation. \n"

# Read Root dir
printf "What would you like to name your root directory? \n"
printf "Directory name: "
read NEWDIR

# Submodule Y/N
printf "Would you like to use Wordpress as a Submodule? [y|n] "
read SUBMODULE


if [ "$SUBMODULE" = "y" ]; then
	# Init git
	mkdir $NEWDIR
	cd $NEWDIR
	git init
	git submodule add https://github.com/WordPress/WordPress.git cms

	# Commiting the submodule
	git add .gitmodules
	git add cms
	git commit -m 'Added Wordpress as submodule in the folder cms'

	# Creating new index.php file
	cp cms/index.php index.php

	OLDWPURL="wp-blog-header.php"
	NEWWPURL="require('./cms/wp-blog-header.php');"

	printf '%s\n' "g/$OLDWPURL/d" a "$NEWWPURL" . w | ed -s index.php;

	# Creating wp-config.php file
	cp cms/wp-config-sample.php wp-config.php

	# Changing linkage to Wordpress files
	printf '%s\n' "g/require_once(ABSPATH . 'wp-settings.php');/d" a "" . w | ed -s wp-config.php;
	echo "define('WP_SITEURL', 'http://localhost:8888/$NEWDIR/cms');" >> wp-config.php
	echo "define('WP_HOME',    'http://localhost:8888/$NEWDIR');" >> wp-config.php
	echo "define('WP_CONTENT_DIR', \$_SERVER['DOCUMENT_ROOT'] . '/$NEWDIR/wp-content');" >> wp-config.php
	echo "define('WP_CONTENT_URL', 'http://localhost:8888/$NEWDIR/wp-content');" >> wp-config.php
	echo "require_once(ABSPATH . 'wp-settings.php');" >> wp-config.php

	# Commiting the environment files
	git add index.php
	git add wp-config.php
	git commit -m 'Adding environment files'

	# Creating new wp-content folder...
	cp -R cms/wp-content wp-content

	# Removing default plugins
	rm wp-content/plugins/hello.php

	git add wp-content/
	git commit -m 'Added wp-content'

else 
	git clone https://github.com/WordPress/WordPress.git $NEWDIR
	cd $NEWDIR
	git init
	cp wp-config-sample.php wp-config.php
	git add .
	git commit -m 'Added Wordpress'
fi

printf "Do you want to keep Wordpress default themes? [y|n] "
read KEEPTHEMES

if [ "$KEEPTHEMES" = "n" ]; then
	rm -rf wp-content/themes/twentyten
	rm -rf wp-content/themes/twentyeleven
	rm -rf wp-content/themes/twentytwelve
	git add -u
	git commit -m 'Removed default files'
fi

# Wordpress Version
if [ "$SUBMODULE" = "y" ]; then
	printf "What version of Wordpress do you want to use? "
	read WPVER
	cd cms
	git checkout $WPVER
	cd ..
	git add cms 
	git commit -m 'Checked out Wordpress version'
fi

# Wordpress Themes
printf "Would you like to add your own theme from a git repository? [y|n] "
read OWNTHEME

if [ "$OWNTHEME" = 'y' ]; then
	printf "Git repository clone URL: "
	read GIT_THEME
	cd wp-content/themes/
	git clone $GIT_THEME
	cd ../../
fi

# Database Credentials
printf "Let's set up the server! \n"

printf "MySQL User: "
read MYSQLUSER

printf "MySQL Password: "
read MYSQLPASSWORD

# Default Credentials
if [ "$MYSQLUSER" = "" ]; then
	set MYSQLUSER = "root"
fi

if [ "$MYSQLPASSWORD" = "" ]; then
	set MYSQLPASSWORD = "root"
fi

# Setup Database
printf "What would you like to name your database? \n"
printf "Database name: "
read DBNAME

echo "CREATE DATABASE $DBNAME; GRANT ALL ON $DBNAME.* TO '$MYSQLUSER'@'localhost';" | /Applications/MAMP/Library/bin/mysql -u$MYSQLUSER -p$MYSQLPASSWORD;

# Setup wp-config.php

perl -pi -w -e "s/database_name_here/$DBNAME/g;" wp-config.php
perl -pi -w -e "s/username_here/$MYSQLUSER/g;" wp-config.php
perl -pi -w -e "s/password_here/$MYSQLPASSWORD/g;" wp-config.php

# Generate Salts
SECRETKEYS=$(curl -L https://api.wordpress.org/secret-key/1.1/salt/)
EXISTINGKEYS='put your unique phrase here'
printf '%s\n' "g/$EXISTINGKEYS/d" a "$SECRETKEYS" . w | ed -s wp-config.php

git add wp-config.php
git commit -m 'Changed the settings in wp-config.php'

if [ "$SUBMODULE" = "y" ]; then
	open http://localhost:8888/$NEWDIR/cms/wp-admin/install.php
else
	open http://localhost:8888/$NEWDIR/wp-admin/install.php
fi