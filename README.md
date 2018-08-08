# washyobutt
Yes, it's' supposed to be like that.

## Introduction
Lately my job has been writing ansible to install and configure Weblogic, JBoss, Endeca, and apache environments for customers who run ecommerce sites based on Oracle Commerce, or ATG.  It’s a fine job; I’ve gotten comfortable with ansible and I’ve learned some things along the way.

Recently my whole team congregated at our corporate office.  Most of us are remote, so when we get together it’s a whole year of socialization, planning, and discussion condensed down to a week.  There’s people who work on a variety of technologies; AEM, ATG, Sitecore, and pretty much any other technology you can host an ecommerce website on.

My company seems to hire young and enthusiastic people.  It’s something I love about it.  During our annual powow, I noticed was almost everyone had a big idea for how the team should function; some new method of dealing with work, some way to push our offering into the future.  Some of them will blossom beautifully into existence, and some are what you can only call Devops fanfiction.  I’ve had enough of these ideas to know that most of them won’t happen.

So this is my newest technology project that won’t happen - a website that does nothing, yet manages to use as many technologies as I can cram in.  I bought the washyobutt.com domain on a lark about 6 months ago after watching the Public Enemy “I Can’t do Nuttin’ for Ya, Man” video on youtube.  I highly recommend it.  I never really had any good use for the domain.  I still don’t, but that’s not going to stop me from building the most over-engineered, needlessly devops-y site I can.

## Tweeting My Commits

The first thing I did was register @washyobutt on twitter, though the website.

### About Git Hooks
I wanted to post all my commit messages to Twitter for absolutely no reason other than dicking around with git hooks.  In git, you write code locally on your computer, then commit it, and push it to github where it’s made available.  A hook is a script that git executes automatically during the commit/push process.  When and where they run is customizable.  There are hooks that run client side (on your local machine) and server side (hooks that run on the github server).  The kind you need depends on what you’re trying to accomplish and what you need.

In my case goals are:
* I want to publish my commit messages to twitter automatically
* I want this hook to be checked in with my code, so I don’t have to re-write it or copy it to every machine I work on.
* I want it to work in Mac, Linux, and Windows.

Server side hooks are based around “push”, when you actually send your committed code up to github.  Client-side hooks are generally based around “commits”, which is where you tell your local git repository that something has changed and you want to keep it.  I usually work with ansible tower/awx, which pulls from git every time it  runs.  I’m used to committing and then pushing every change so I can test it.

In the spirit of how hooks work, I’m going to use client side hooks.  There are a few events where hooks are called.  In my case, I’m just pushing information around; I’m not enforcing any policies or affecting my commits in any way, so I decided to use a post-commit hook.

Since I said I want my hooks to be portable, I should probably not write them in bash.  I use a Mac for work, Ubuntu for projects, and Windows for my home PC.  I won’t be using my work laptop for this, but I’d like to have a hook that I can run on any computer I happen to be in front of.  I like python, and it’s platform independent, so I’m going to use that.  

### The Twitter API and OAuth
I’m going to take a break from setting up the hooks to learn about the twitter API, since that’s what I’m going to be talking to.  I don't want to open a browser and post my tweets, so I need to send them directly through the twitter API.  To do this, I need to set up OAuth keys, which will allow me to authenticate with twitter.

#### The Keys

To get the keys and create the application, you go to https://apps.twitter.com/ and sign in with your twitter account.  There’s a big-ass “Create new App” button.  Press that and you’ll get a setup form.  I filled it out, but left callback URL empty because I don’t want Twitter to return me to any site in particular.

The twitter API uses oauth.  The concepts I’m talking about apply to oauth-based api’s, although the exact terminology may differ slightly.  

Once you create your app, you’ll see your Consumer Key.  Right next to the Consumer Key, you’ll see a link that says “Manage Keys”.  This is where we’re going to create the actual keys that will let us post shit to twitter.  If you click in there, you’ll see a button at the bottom to generate access tokens and secrets.  Copy those down and keep them safe.

You’ll end up with four keys at the end.  Here’s what they are and what they’re for:

Consumer Key: This tells twitter who you are, at at the application level.  My application does one thing - posts commit messages from github as my user.  Therefore, my user and my application are pretty-much the same.  If you consider a large application or a research project with multiple users who are collecting, posting, or analyzing tweets, it makes sense that there should be a layer of abstraction between the user and the application.

Consumer Secret: This is the private half of the consumer keys.  It’s not transmitted like the consumer key is.  You know this, and twitter knows this.  It’s analogous to your password.  It’ll be used later to compute authentication information.

Access Token: Since my “application” is acting on my behalf and posting tweets as me, I need an access token.  You use your consumer keys to tell twitter "I'm the washyobutt application", so now you need to use the access token to tell it that I'm a user who is allowed to post.  The consumer key is application-based, and the access token is user-based within the context of the application.

Access Token Secret: This is the secret part of your access token.  It’s pretty-much the same deal as the consumer secret; it’s the private half of the exchange.

#### Understanding the OAuth Headers

I’ll be talking to the twitter REST interface.  I’m going to use a library specifically for this purpose, but it’s good to understand what’s happening behind the scenes.  According to the twitter docs, you can post like a tweet like this:

```
POST https://api.twitter.com/1.1/statuses/update.json?status=This%20is%20my%20post
```

The %20 are url-encoded, or percent-encoded, spaces.  You can url encode/decode using an online tool like https://www.url-encode-decode.com/.

That’s simple, but first you have to authenticate by adding some extra HTTP Headers:
```
Authorization:
OAuth oauth_consumer_key="xvz1evFS4wEEPTGEFPHBog",
oauth_nonce="kYjzVBB8Y0ZFabxSWbWovY3uYSQ2pTgmZeNu2VS4cg",
oauth_signature="tnnArxj06cWHq44gCs1OSKk%2FjLY%3D",
oauth_signature_method="HMAC-SHA1",
oauth_timestamp="1318622958",
oauth_token="370773112-GmHxMAgYyLbNEtIKZeRNFsMKPR9EyMZeS9weJAEb",
oauth_version="1.0"
Content-Length: 76
Host: api.twitter.com
```

This is from the twitter API documentation; it’s wrapped here for readability.  Again, I’m going to use a 3rd party python library to do this work for me, but it’s worth taking some time to understand OAuth.  You can read about oauth until your eyes fall out, but I want to at least understand the headers for twitter and what they do.
 
The consumer key we talked about above - that’s what tells Twitter which application I am.

The nonce is a unique 32-character string that twitter uses to detect duplicate requests.  This needs to be unique.

The signature is the interesting part.  This is used to verify your access, your user, and also let’s twitter tell if your request has been altered in transmission.  It’s a computed value based on a hash of the request created with your secret information.  If you were to construct this, you’d take all the other parameters from both the http headers and the url, jam them all together and percent encode them.  Then you’d do the same with your sensitive information - your consumer secret and your oauth token secret.  Now you feed your jammed together encoded request and your jammed together sensitive information through a hashing algorithm to get a binary string, which you then convert base64.  Twitter will create the same sensitive string and use the same hashing algorithm verify your request.

The oauth signature method tells twitter what hashing algorithm you used to generate the signature.

The timestamp is the time that the request was created, in seconds since the unix epoc.  Twitter won’t post old tweets, or tweets from the future.

The Oauth token is the oauth token value from the apps.twitter.com site.

The oauth version is the version of oauth to use.  Twitter uses oauth 1.0, so this is always the same.

### Setting Up Git
Now that I understand the twitter API and I have my keys, I need to start on the actual hook.  

#### Creating a Local Repository
First I’m going to need a git repository.  I’ll start by initializing a new project in git with git init. 
```
mkdir -p ~/Projects/wyb
cd !$ 
git init
```
!$ is my favorite bash shortcut.  It's a built-in for the last argument of your previous command.  In the example above it would expand to cd ~/Projects/wyb.  Very useful.

I want to keep all my shit in one place (~/Projects/wyb), so I’ll use this for the whole project.  However “all my shit” includes sensitive data like api keys and a directory of misc notes and templates for my own reference, so I better create a .gitignore file in my project so I don’t end up checking it in.

```
#Exclude private and reference directories
/private
/notes
```

Now I have a local git repository, but nowhere to push it, so I need a repository on github.com to push my stuff. 

#### Creating the Repository on Github.
Log into github and push the big, green “New Repository” button.

With that complete, I need access to it.  I have some existing projects and keys on my github account, but I’ll create a new ssh key for this project.
```
ssh-keygen -f ~/.ssh/wyb -t rsa -b 4096 -C “mattdherrick@gmail.com”
```
That creates a public and a private key in my home .ssh directory, encrypted with rsa with a size of 4096 bits, and my email address as a comment.

Now that I have a key, pair I’ll add the .pub (PUB!) half to my github account under Profile > SSH and GPG keys.

#### A Quick Side-Task in Bash
Before I do that, I’m going to install xclip.  Xclip will let you copy terminal output directly to ubuntu’s clipboard.  Since 99% of what I do is copying and pasting from people who know what they're doing, I’m going to use it a lot.
```
sudo apt-get install xclip
```

By default, you need to middle click to paste from xclip because it goes to a different buffer by default.  I want it to go to the actual clipboard because I was raised with ctrl + v, not this middle click bullshit.  I’m going to put an alias in ~/.bash_aliases

```
alias pbcopy=’xclip -selection clipboard’
```

Why pbcopy?  I use a mac most of the time, and it’s the command in OSX to copy output to your clipboard.  I’m not smart enough to keep track of the platform I’m working on.  If you were some kind of OS purist or had any principles at all, you'd probably just alias 'xclip' to 'xclip -selection clipboard'.


#### Back to Github
Now I’ll get my public key, and paste it into my github profile under “SSH Keys”.  Part of the reason I'm a stickler for xclip is that keys are sensitive to extra spaces and characters.  By using xclip, I'm sure I'm not dragging my mouse over an extra whitespace or grabbing part of my command prompt.

```
cat ~/.wyb.pub | pbcopy
```

Create a new key in the github profile, give it a name, and paste in the public key from the clipboard.  Now I should be able to push from my local github repo to my remote repo.

Most people use github by memorizing a few commands, and then using them until something goes horribly wrong and frantically googling it.  I am no different.  It’s a lot to unpack and understand, but I’m going to touch on the high level concepts a bit as it pertains to what I’m doing.

I have a local github repository that I made with git init, and a remote github repository I created through github.com.  I need to hook them together by adding the github repo as the remote.  The other (easier) way to do this is create the repo on github and then clone it, but I think this way illustrates how it works a little better.

A remote is exactly what it sounds like; a remote github repository that you want to push to.  Here’s the command:

```
git remote add origin https://github.com/ozmodiar192/washyobutt.git
```

“Git remote add” makes sense, but what's the deal with "origin"?  You’ll see origin a lot in the git world; it’s the default label on your local system for the remote repository.  I could name it anything.  It's a good convention, and it's usually named that way in examples and on stackoverflow.  As I said, most of what I do is copying and pasting out of stack overflow.  When you clone a repository with git, as I recommended above, it creates a remote for you automatically called "origin".

So now I should have my git repos hooked up, so I’ll add a README.md file.  That’ll display on the github page.  Eventually it’ll be this document, but for now I’ll put some dummy text in there.  I’ll edit the file and then do
```
git add *
```
If I changed a bunch of files and only wanted a subset or them, I would use a different pattern in my add command.  Now I’ve got the file added to my project, I’ll commit it.
```
git commit -m “Initial edits to readme.md”
```
-m is the comment I want to use.

So I have my file added, and I told git it’s something I want to commit.  Now I need to push it up to github.

The main branch in git is called “Master”.  Right now I’m working on master, but eventually, when I’m adding new functionality, I’ll probably branch.  For the time being I need to tell git that I want this to go on the master branch.
```
git push --set-upstream origin master
```
That means push it, and set it up to go to the master branch of origin, which you recall is the alias for the remote repository.  If I had named my remote repository “washyobutt” and I were on branch “firstbranch”, I’d do git push --set-upstream washyobutt firstbranch.

Now I’m able to get stuff into github.

### Setting up Python and Writing the hook
I’m going to break this up into two sections - Writing a hook in python that gets my last commit message, and then building out the twitter api stuff.

Hooks are stored in, and run out of, the .git/hooks directory, which doesn't get checked in.  There’s some samples in there when you create you project.  I want to include the hooks in the actual source code because I want to have all the ridiculous work I did available.  Therefore, I’ll create a hooks directory in my project, and then symlink it to the .git/hooks directory.  

The downside here is that I’ll need to remember to do this every time I check out the project.  I may go back and find a very complicated solution to this simple problem later.  For now I'll move the built-in samples from the /.git/hooks directory to /hooks, and then link /hooks back to /.git/hooks.

I determined earlier that I’d use a post-commit hook, so my file needs to be named post-commit.  You can’t name the hook whatever you want, which is a bummer because thetwittercommitter has a nice ring to it.  Also note that you can’t have a file extension.

#### Setting up Virtualenv

Python 2.7 is on my laptop already, but I want to set up virtualenv.  VirtualEnv lets you manage different python installations; I highly recommend it.  I already have the python package manager, pip, installed.  If you don't, the package is something like python-pip.

```
sudo pip install virtualenv
```

You have to use sudo for this part because the built-in python installation puts packages in a directory that isn't writable except by root.  We’ll fix that with virtualenv.

Now we’ll create a virtual environment for python 2.7, which is what’s on my machine by default.  Or maybe I put it on there.  I don’t remember.
```
virtualenv python27
```
That’ll create the environment in ~/python27.  Now I need to tell Ubuntu I want to use it

```
source ~/python27/bin/activate
```
Now when I use python, it’ll use the copy there.  Furthermore, I can write there, so I don't need to use sudo for everything.  I want this to be my default python installation, so I’ll add the command to source the activate script into my ~/.bash_profile.  Later, if I start messing with more installs of python, I might take this out.

The thing I don’t like is that virtual env adds the name to my terminal prompt:
<(python27) matt@ubuntu-tpad:~/python27/bin$>

To get rid of that, I’ll comment out the section in the activate script that references PS1, which is the default prompt.  I’ll re-source the file, and it goes away.  Now I can run pip without sudo.

#### Installing the Python Libraries

```
pip install tweepy
```

I also want to store my sensitive shit in a properties file in my private directory, which I added to my .gitignore earlier.  I’m going to use the ConfigParser lib to do that.
```
pip install configparser
```

Here’s my initial stab at a hook.  Since everything will be in github, I won't paste it in here, but this is a transitory file to show the basic idea.
```
#!/usr/bin/env python
#.git/hooks/post-commit
from subprocess import check_output

commitmsg = check_output(["git", "log", "-1"])
print(commitmsg)
print(len(commitmsg))
```

It uses the python subprocess check_output command to execute and get the output from the git command “git log -1”, which shows the last commit.  I also write out the length because I want to make sure my commit messages are less than the 280 character limit of twitter.  This is just my placeholder, so I’ll handle the output later.  I tested this and it worked fine.

So now I need to get talking to twitter.  I had previous thought about doing this all from scratch using the built-in Python urllib, but there are so many twitter api libs for python it seems stupid and inefficient to reinvent the wheel.

The working script is up at github.  My sensitive data file is formatted like this, for your reference:
```
[Consumer]
ConsumerKey=mykey
ConsumerSecret=mysecret

[Owner]
Owner=washyobutt
OwnerID=myownerid

[Access]
AccessToken=myaccesstoken
AccessTokenSecret=mytokensecret
```


## AWS
Now I need to actually start building something.  It seems like everyone uses aws, so I’ll start there.  At this time, I’m going to spin up a single instance, but I’m going to do everything in terraform because that’s what people on stackoverflow do.

### Terraform
Terraform is a way to represent your aws infrastructure as code.  It seems more complicated than it is; I’ve found it be pretty easy to use once you get going.  Between the aws docs and the terraform documentation, it's pretty easy to figure out what everything does.

I have an aws account already, but I don’t have my api keys.  Terraform is going to talk to the api, so it needs keys similar to what I used for the Twitter api, only there’s no consumer key because there’s only one ec2 application.

I’ll get them from my profile under My Security Credentials.  Again, I don’t want them in github, so I’ll put them in a tfvars file named terraform.tfvars, and add \*.tfvars to my .gitignore file

The secret vars file is in terraform/terraform.tfvars and looks like this:
```
accessKey = "myAccessKeyRightHere"
secretKey = "SuperSecretKeyRightHere"
```
The other option is not specify aws credentials, and store them in ~/.aws/credentials.  Terraform checks there by default, but I think I want to keep them in the project to have everything self contained.

You can’t just reference the tfvars directly; you need to set them actual variables in Terraform. I’ll put them into vars.tf.  I’m going to use vars.tf for all my variables, and any data that I’m pulling in externally and referencing later.  You can structure terraform however you want, because it’s smart enough to find all your references no matter where you store them.  

Before I start spinning shit up, I want to add a keypair and security rules so I can actually connect to these instances.  Eventually I’m hoping I won’t need to.

As you recall, I already generated a keypair for github.  If I use it for both github and AWS, and someone gets access to my private key file, they could then not only fuck with my github repo a bit, but they could get on my ec2 instances as well.  That sounds like bad news, but I’m not really storing these private keys anywhere except my laptop.  I’m not putting them on a shared drive or anything.  So, if someone got access to one, they’d likely have access to all of them anyway since they’re all hanging out in my .ssh directory.  If I had put passphrases on my keys, it might be a different story since there would be a layer of protection there, although ssh key passphrases could probably be brute forced pretty easily.

That paragraph might sound like my way of saying “fuck it”, but at least for now, wyb doesn’t have anything sensitive anyway so it doesn’t matter.  I try to think through security, even though I sometimes take the lazy way out.  “What if someone got this key?  What could they do?”  is a good question to continually ask yourself.  In this case, the answer is “break my website that doesn’t exist anyway” and “check more shitty code into my shitty code repository”.

I could manually put this keypair into the Amazon EC2 console and then associate it with instance when it comes up, but I want to create the keypair as part of my terraform job.  I created another new terraform file called “security.tf” where I’ll create all my security-related stuff.  Since my public key is public, I can put it right into terraform, in my vars file.

Now that I’ve got my key situation squared away, I also need a security group.  Security groups are pretty-much firewall rules for the ec2 instances.  Right now I’m going to use short-lived instances and log in manually, so I’ll need to open ssh (port 22).  

I could open it up to the world and rely on the security of my private key but that’s boring, so I’ll get my external IP address with a terraform http data source in my vars.tf file, which will call out to icanhazip.com to get my local machine’s external IP.  I love icanhazip.com; it returns your ip address with no extra formatting or bullshit.  I think it has a carriage return in it, though, so had to use the terraform chomp filter on it.  This may not be very sustainable for the long term, but since I’m dicking around at home and tearing things down right away, it’s a fun way to do it for now.  “Fun” being a very relative term.

Now I can create an entry for my ec2 instance, making sure to reference my key pair and security group.  This is in ec2.tf, along with the provider definition for aws that reads in my credentials.  I'll quickly go over the terraform syntax for this ec2 instance.

```
resource "aws_instance" "wyb-singleton" {
  ami             = "ami-2757f631"
  instance_type   = "t2.nano"
  key_name        = "wyb.pub"
  security_groups = ["allow_ssh"]
  tags {
    application = "washyobutt"
  }
}

```
The first line is telling terraform I want to create an aws_instance with a name of "wyb-singleton".  The types are all available in the terraform documents. The name is the name that terraform will use to reference the resource.  Some resources have both the terraform name, and a name for EC2 (like my security policy).  You can name them however you want.  Within the brackets are the configuration parameters for the resource type you're creating.  There are usually lots, and you can find them in the documentation.  Finally, you have 'tags', which are a way to organize your hosts within EC2.  You can use tags for filtering your resources, and also for billing.  I just gave mine a generic tag called "application" with a value of "washyobutt".



So if I run this, it works!
```
terraform plan
```
Shows what I expect, and if I run
```
terraform apply
```
Everything gets created.  If I do
```
terraform show
```
To get the public dns of my instance, I can log into it with
```
ssh -i ~/.ssh/wyb ubuntu@<myPublicDnsThatIJustGotFromTeraformShow>
```

Things are coming together nicely, however terraform has left it’s state files in my directory.  Terraform maintains the state in static files by default.  That’s fine if you’re like me; a single dude (ladies?) working solo on a small project.  I could safely add them to .gitignore and continue on my merry way, but I saw an article the other day that said “Why You Should Be Using Remote State in Terraform”.  I didn’t read it, but I can only assume the author made a compelling argument.

The main reason you’d want to mess around with the terraform state files is if you’re working on a project with other people.  Terraform needs that state file to be accurate, so you have to treat it with care.  If Sue Developer is trying to build with terraform the same time as Jane Developer, it’s going to go badly.  You can’t track it with git because you have no idea if someone else has updated the environment.

Luckily, we can use Amazon s3 to store our state file.  And we can create the s3 bucket with terraform.

#### Setting Up Terraform State

The high-level process for this is to create an s3 bucket, then tell terraform to store it's state there.  S3 is Amazon's file storage service.  They call an S3 object a "bucket", and that's a useful way to think of it. Once I have my state stored remotely, I'll set it up to use locking because that's what a lot of real people do.  If you have multiple people using terraform, you would want your state to lock so people can't fuck it up by running things simultaneously. Since I'm doing this solo, I'll have to find some other way to fuck it up.

I'm trying to keep this project cheap, so the idea of having a persistent s3 bucket out there is off-putting to me.  However, the tfstate is tiny, so if it costs anything at all, it'll be negligible.

It's a simple process to set this up; the best guide is https://medium.com/@jessgreb01/how-to-terraform-locking-state-in-s3-2dc9a5665cb6, but I'm going to do my best to complicate it.

## AWS IAM Setup
While looking into Bucket policies that I might want to add, I realized that my Amazon AWS account is set up with a root user only.  The root user is the one I use to sign to the AWS console.  Amazon recommends that you not use the root user for anything other than setting up IAM.  IAM is Identity and Access Management.  I'm going to implement a very simple IAM setup.

Log in to the amazon AWS console at https://console.aws.amazon.com and find the Security, Identity, and Compliance section.  Under there, click on IAM.  You'll see a handy little checklist that explains all the ways you suck at security; "Delete your root access keys", "Activate MFA", etc.  For now, I'm just going to create my IAM user and worry about making the Security Status thing happy later.

Click on Users, and add a user.  I'm going to name mine terraform.  I'm going to give it Programmatic Access because I don't want anyone fucking around in the console with the terraform user.  Once you start using terraform, you've sold your soul to it; you don't want to do some shit manually and some shit in the console because it'll create drift and fuck up your state.  You can import things to terraform that you created manually, but that's a sucker's game.

I'll create a group for "api-full-access" and assign the built-in AmazonECFullAccess and AmazonS3FullAccess policies.  Amazon will provide the access and secret keys, which I can update in my private information store and tfvars.  If you were inclined, you could construct a very detailed policy around terraform, but I have no need for that now.  My goal is to understand conceptually without doing a whole bunch of legwork.

In the spirit of IAM, I'll also create an administrative user and an administrator group with the "AdministratorAccess" policy.  I gave this group access to the console as well as the api.  From now on, I'll use this user to sign into the console.

This has knocked out two tasks on my security status checklist in the IAM section of the aws console; I may as well finish it off by creating an IAM password policy, setting up MFA on my root account, and nuking my root account access tokens.  I clicked on Apply and IAM password policy and then used the "Manage Password Policy" button.  I used good ol' fashioned common sense and created a password policy that will work for me.

To setup MFA and delete the access keys from my root account, so I signed out of my IAM account and back in with root, and went back to the iam section of the console and followed the prompts in the checklist. 

I decided I'd manage at least the initial two users outside of terraform.  It would be a tall order to make terraform create the user that runs terraform, and I don't really want to fuck with my administrative console user with terraform.  If I were inclined, I could import these resources into terraform and allow terraform to manage them (terraform import aws_iam_user.wybmatt wybmatt).  If I ever need more users, I'll manage them with terraform.

#### Back to S3

To set up my remote state bucket, I created an S3 bucket and then defined it as the backend for terraform.  I put this in a file called setup.tf; that's where I'm going to store all my terraform configuration stuff.  I also moved the aws provider in there.  I also followed Jessica G's advice and created a dynamo db table for state.

#### Dynamo DB

DynamoDB is an Amazon service.  There are roughly a billion different amazon services, and I'm going to try to use as many of them as I can.  By doing this, it'll allow me to name drop them in casual conversation with my nerd friends, and I'll list them as skills on my LinkedIn profile even though my understanding of them is rudimentary at best, negligent at worst.

DynamoDB is non-relational database service.  Traditional databases like Oracle and SQL Server are relational; they store data in columns and rows in tables.  I might have a table for users, and each user will have an ID that serves as the primary key for that user.  A primary key is a unique value for each row that serves as the main identifier for that resource.   I can then link that user to other tables in the database, like "email addresses" and "wrongs committed against me".  The primary key, userID, would be set to the  "foreign key" of the "wrongs" and "email address" table.

A non-relational database, or a nosql database, doesn't give a shit about maintaining relationships between data.  They store data in a variety of ways; in the case of DynamoDB, there are still tables, but instead of the tables being linked, they're inclusive lists of attributes.  Using my example above, I would have a table called "users", but the "users" table would contain attributes for "ID", "email address" and "wrongs committed against me".  This is a little more intuitive and more flexible, since I can really have any information I want in the table.  I can note that Barry smells like tortilla chips, and that Andrew has a geographic tongue, without the overhead of creating tables for "smells" and "upsetting physical attributes".  Note that, at least in DynamoDB, there is still one requirement; each record still uses a primary key!

Which brings me to what started me down this road - figuring out why the "hash key" for the terraform DynamoDB table I'm creating has to be "LockID".  Hash key and Partition key are the same thing - they're types of primary keys.  Terraform is written to look for a DynamoDB record with a primary key of LockID.

I also had to check why I need a type of "S", but that was a simpler concept.  S is for String, N is for Number, and B is for binary data.

#### Terraform Remote State Sucks

I commented out the backend resource from my setup.tf, ran a terraform apply to create the S3 bucket and dynamoDB table, then uncommented out the backend.  I had to go back to my IAM user and add the AmazonDynamoDBFullAccess policy, but otherwise it went smoothly.

To change the backend, I had to run terraform init again.  It failed due to a bug in Terraform.  Apparently the backend configuration doesn't use the same code as the rest of terraform.  It was failing on my security keys, which you recall I'm storing in a terraform.tfvars file that I have secured and gitignored.  It seems like the two options here are:
1) Put my credentials directly into the terraform setup.tf file
2) Put my credentials directly into the terraform init commmand

I did the latter, but this is yet another manual step I'll have to do if I ever change laptops or bring in more members on the Washyobutt team.  If you're a security-minded person, you would also edit your ~/.bash_history file and delete the commands containing your sensitive info from your history.
```
 terraform init -backend-config="access_key=MYACCESSKEYISMYOWNBUSINESS" -backend-config="secret_key=ThIsI5mYAc355K3YRiGh7H3R3F3LLA"
```

The good news is that this worked, the bad news is that it kind of sucks.  The problem comes when I want to destroy.  I specified 
```
    lifecycle {
      prevent_destroy = true
    }
```
on my S3 bucket, which is a smart thing to do.  However, when Terraform encounters this, it doesn't just skip destroying it.  It exits, errors, and stops processing.  That's not what I want; I want to freely destroy without breaking my state file.  I tried removing prevent_destroy and that was an even bigger disaster as you might expect; it couldn't unlock the state file because I deleted it mid-way through the run,  and I had to convert back to local state in order to clean it all up.

If you're working on something that you're not tearing down, you wouldn't have an issue here.  You could just plunk along, happily adding infrastructure and updating your shared, locking, badass tfstate table.  But the thought of my singular, nano-sized EC2 instance out there, robbing me of pennies every month, has my jimmies sufficiently rustled.

What to do now?  If I could do an exclude on my setup.tf resources, or if terraform just continued on rather than exiting when it encountered my prevent_destroy stuff, I'd be fine.

#### Fixing Remote State

I spent a bunch of time trying to make remote state work.  My goal was to have the state infrastructure defined in terraform, but it just wasn't in the cards.  First I tried creating a new directory where I put only the state-related infrastructure (the s3 bucket, the dynamoDB table, and a backend for state).  That worked, until it came time to apply the rest of my infrastructure.  The issue was that the backend was now servicing two distinct terraform directories, so when I did "terraform plan" in my directory, it flagged my infrastructure shit for deletion because it was in the state file, but not defined in my current working directory.

I considered importing the objects, but that won't work either, because importing something puts it under the management of terraform.  That would put me right back to my original problem; I don't want to tear down my state-related infrastructure when I'm tearing down everything else.  I tried using different keys for my infrastructure and my main stuff, but that didn't seem to work.  The "key" should be the path within the bucket where things are stored, but I wasn't sure how that works when you're using DynamoDB, and I honestly didn't spend a lot of time on it because I realized I was just being stubbornly principled on this whole state thing.

Eventually, I bit the bullet, nuked setup.tf, and manually created the dynamoDB table and S3 bucket in the console.  Then I defined the backend in terraform in my backend.tf file, and everything worked fine.  That leaves my S3 bucket and DynamoDB table out there, totally isolated from terraform, as long as I never import them.  I honestly think this is the best way to do it, even though I consider it a minor compromise to my intention of creating a fully self-contained infrastructure.  I may create some amazon CLI scripts to do tihs in the future, just to make it a little more reproducible from github and alleviate my weird hangups about having as much as possible automated. 


## A VPC of My Own
When you spin up an EC2 instance or something on Amazon, it creates a default VPC for you.  This is Amazon shielding you from the ugliness of routing, IP addressing, and Internet gateways.  You can continue on your default VPC happily, never realizing it even exists.

If your needs grow, you might find yourself in need of a more sophisticated networking setup.  My needs have not grown, however I wanted to set up a VPC from scratch for my washyobutt application, because I feel like using the default one robs me of my IT legitimacy in some way.  When you tell Amazon you're using a non-default VPC, shit suddenly gets a little more complicated.  You have to make a routing table, populate it with routes, create your own Internet gateway, and start specifying an IP scheme for your environment.  Whether you use it or not, my advice is not to fuck with your default VPC.  Don't clean up the subnets, don't mess with the routes, just leave it alone.  A VPC doesn't cost you anything; it's what you put on it that costs you money, so the default VPC hanging out there with nothing on it isn't going to run up your Amazon bill.

I put all my VPC-specific settings in vpc.tf.  I also moved everything to a per-vpc sub-directory of terraform within my project.  That way, if I ever create another VPC for internal infrastructure or another website, I can keep it's terraform configuration totally separate.  If you look through my terraform shit, you'll see the resources now reference my vpc by the variable "${aws_vpc.wyb_public.id}".  Terraform lets you work with friendly labels when you create things, but when it comes time to hook everything together you will find yourself using a lot of IDs, which you grab using that syntax.  ${resource_type.the_name_you_gave_it.the_attribute_you_want_which_is_usually_id_but_sometimes_not}.  Again, this looks impressive when you're digging around in terraform, but in practice it's pretty simple.

The hardest part is understanding the VPC conceptually.  It's basically a network segment, with it's own devices, routes, and everything a network needs to function.  Right now, mine is very simple.  A VPC, a single instance, a gateway to allow internet access, a subnet, and a default route.  Everything is cross-referenced in a variety of ways, which are spelled out pretty plainly in the terraform documentation and makes sense if you're familiar with networking concepts.  There were two changes that weren't very intuitive and caused me some hassle; when I started using my own VPC, I had to convert my reference to the security_group (allow_ssh) to use the id instead of the name, and I had to start specifying how I want to address my instance, because it stopped giving me a public IP by default.  Right now, I just assigned it a public IP address.  Eventually I may use NAT, or elastic IPs, or something else.

## Content
It's about time to actually put up content and an actual website.  The first iteration of WYB will be pretty simple; a single webserver and a single page.  I haven't written html or css, so I spent some time figuring it out.  Like most things in IT, it's pretty easy to do it poorly, once you understand the basic idea.  I wanted an old-school looking flashing, blinking, HTML monstrosity, but things like blink and marquee are either gone from the HTML spec or considered unsupported.  Browser support is dubious for them for taste and accessibility reasons.  I found someone with a blinking .css, but it doesn't have that shitty, geocities feel I was going for.  I settled on it because the last thing I want to do is get hung up on web design on this website project.

## Deploying
I have a functional website, but there's no way in hell I went through all this automation to have to copy it up and install a web server every time I run my terraform scripts.  There's a few options for automation here: I could write ansible scripts or something and run it locally, using an inventory generated from terraform.  I could probalby use Amazon CodeDeploy and an image file (ami) with a webserver on it already.  Using an ami with a pre-built webserver doesn't seem devops-y enough, you know?  What if I need to use a different ami some day for some reason?  What if I want a specific version of nginx?

I could use cloud-init to do it.  Cloud-init and userdata are parts of the cloud-init system.  They both run the first time you start up an instance.  User data scripts are bash shell scripts, whereas cloud-init is a more declarative, directive-based set of tasks.  There's room for personal preference; if you like bash and want to do the whole thing as a shell script, use a user data script.  If you aren't, you can do a lot with cloud-init before you have to dive into linux commands.  Hell, if you wanted to, you could write it all in python or ruby or whatever, store it in an s3 bucket, and then download and run it with a single, one-line user data script.

The last option, and the one I decided to use, is the built-in terraform provisioners.  I don't like the syntax, but my initial provisioning is so incredibly simple that it's an easy thing to throw in terraform.

The first thing I'm going to do is spin up my instance and manually configure it so I can see exactly what's needed, anticipate any issues, and then build it into terraform.

### Manual Setup
I ran terraform apply to spin up my environment at Amazon, and then used ssh ubuntu@my.public.ip to connect.  I got the public ip from running terraform show, however I noticed that since switching to a non-default VPC, I no longer have a public DNS name by default.  I'll have to fix that later; it's a setting within your VPC that you have to set manually from the ec2 console.

I did an apt update and install the nginx package, and it started up just fine.  I looked at the conf file in /etc/nginx/sites-enabled/default to see where I should put the content.  As expected, it's /var/www/html.  For now, I'm happy using the default nginx configs so I'm not going to mess with anything.  I'll checkout my code and content from github, link the /content directory of my project into /var/www/html, and I'll have a stew goin'.

## Delving Into Terraform Provisioning
To use the terraform file provisioner, you need both a definition for the provisioner and set up for the connection it should use.  These are both in ec2.tf since they're declared as part of the ec2 instance setup.  The connection definition needs your private key so it can authenticate with your instance.  For the time being, I'm going to use my wyb private key that I use to connect.  I could create a new key, and add a second aws_key_pair resource with its public key to my security.tf file so it ends up on my ec2 hosts, but I decided not to since I don't see this current configuration as a desired end state.

I wanted to make the private key a variable in my terraform.tfvars file so future wyb developers could use their private keys by editing one file. However, the private key is long and I want to read it in from the file.  Pasting in a giant private key is a bad idea for a bunch of reasons.

My desired state was to read in the private key from the file in my terraform.tfvars file, but that doesn't work.  It would've looked like this:
```
ec2SecretKey="${file("/home/matt/wyb")}"
```
and then a reference to ec2SecretKey in my vars.tf and reference it neatly within my connection definitions.  However, tfvars doesn't support variable interpolation at this time, so that's impossible.  I had to make yet another compromise and put the reference to the private key directly in the connection definition of the provisioner within ec2.tf.  That means, when washyobutt takes off and I have a huge team of IT superstars (Ohad Levy, Linus Torvalds, Andrew Replogle: hit me up on LinkedIn!), they'll need to modify the file after checking it out.  That's a problem for a bunch of reasons; it'll be checked in different ways to github and it's making my configuration more diffuse than is tolerable to me.  You shouldn't have to edit the code after you check it out.  For now, I'm going to put a pin in it because working around terraform variable limitations seems too boring to deal with, but I'll be back.

The good news is that it works.  I threw the rest of my commands into the provisioner, and now washyobutt.com automatically appears after my terraform run!

The next thing I need is DNS.

### Route53

I'll use Route53 to host my DNS.  Terraform can manage other DNS providers, but Route53 is easy to use with the other Amazon stuff I've already configured.  The traditional DNS concepts still exist, although there are some additional features and minor differences with Route53.

One of those new concepts is delegation sets.  Since Route53 is highly distributed, you aren't guaranteed to have the same name servers for each of your dns zones.  When you create the zone, Amazon assigns you four name servers, and you have no guarantee what they'll be.  The four records are called a "delegation set".  An uncertain delegation set would be a pain in the ass if you have a bunch of domains registered somewhere outside of AWS.  You'd have to compile the name servers for a bunch of domains with a mishmash of authoritative DNS servers and point your external provider at them, and update them if you tear down and recreate your DNS zones. Therefore, Route53 allows you to make "Reusable Delegation Sets", which is just a static list of 4 name servers that you'll use for all your DNS.

I registered washyobutt.com at namecheap for some reason (it must've been cheap), and terraform does not currently support the namecheap api, so I'll need to do some dns setup out-of-band.  There's built in DNS for NameCheap, but I don't want to use it for my DNS records; I want to point it at Route53 so I can dynamically update with the rest of my terraform/aws stuff.  I logged in and looked at what's at Namecheap, and right now it's a CNAME (alias) that points to some parking page that probably has a bunch of ads on it if you're not using adblock.  Gross, sorry.

The issue I have is that I treasure the ability to tear down the environment, but I also don't want to continuously edit my namecheap records to reflect updated DNS servers at Route53.  I'm trying to minimize the number of persistent resources I keep up and running, at least until I have the website at some kind of desired end-state.  Tearing down a reusable delegation set defined in terraform kind of defies the point of having one, so that won't help me much.  I could do a bunch of bureaucratic stuff to transfer my domain to Route53, and let that update my authoritative DNS servers automatically.  After some deliberation, I thought I'd create a reusable delegation set outside of Terraform, point namecheap at it, and then just reference it in my Terraform config.

Unfortunately you can't create a reusable delegation set in the AWS console; it must be done through the API.  Terraform is happy to do this, but I don't want it in my state and I don't want to manage it.  This is the second time I've created AWS infrastructure outside of Terraform; the first was when I set up terraform's state management stuff.  This is a trade off I'm making between needing persistent resources, and wanting my stuff to be ephemeral.

To create my reusuable delegation set, I did
```
pip install awscli
```
and then ran
```
aws configure
```
and fed it the terraform access key and secret.  AWS and Terraform both check for credentials in a few places, so I made sure to unset any environment variables I set while messing around
```
for var in AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN AWS_SECURITY_TOKEN ; do eval unset $var ; done
```

Then I ran:
```
aws route53 create-reusable-delegation-set --caller-reference `date +%s`
```
This created a reusuable delegation set for me.  Caller-reference is a unique string, so I just used seconds from the linux epoc. That barfed out this output:
```
{
    "Location": "https://route53.amazonaws.com/2013-04-01/delegationset/N3DWCHIKKR8MP4", 
    "DelegationSet": {
        "NameServers": [
            "ns-581.awsdns-08.net", 
            "ns-1815.awsdns-34.co.uk", 
            "ns-488.awsdns-61.com", 
            "ns-1299.awsdns-34.org"
        ], 
        "CallerReference": "1533057420", 
        "Id": "/delegationset/N3DWCHIKKR8MP4"
    }
}
```

Now, when I create my DNS zone for wyb, I'll just reference the ID of my permanent delegation set, which is N3DWCHIKKR8MP4.  I can point namecheap to the four name servers listed above, and I'll be able to freely create and destroy my dns zones while always getting the same four name servers.

### Welp, the site is up, I guess.
I now have what people in software consider a "minimally viable product".  Minimally viable product is really just a nice way of saying "we're figuring this out as we go along", but my intentionally terrible and useless website now spins up from next-to-nothing with a single command.  Revisiting my notes, I have a few things I'd like to do before I continue on with my project and make it slightly more viable, but no less terrible and useless.

1) Get my keys in order and audit my security settings.  Investigate service roles/assume roles so users can escalate their permissions for automation purposes.
2) Script out the creation of my dynamodb table, s3 bucket, and reusable delegation set.  This script should output the vars directly for terraform to consume.
3) Create a project initialization script that sets up the environment for you as much as possible.
4) revisit my git hook.  I'd like to link to specific commits since I'm treating readme.md as a dev log.

## Revisiting IAM
I wanted to implement assume roles vs. dedicated users for provisioning.  Assume roles are a way to temporarily elevate access; rather than giving individual users permissions to do what they need, you give them access to your role.  This gives you a centralized place to delegate pre-configured access levels.  I absolutely don't need to do this since I'm one person, but I read an article about some company with a crazy amount of microservices, and this is how they do it.

First I logged into the console and created a role.  I gave it the same permissions as my terraform user; full access to S3, EC2, DynamoDB, and Route53.  As you probably don't recall, when I created my terraform user, I put it in a group called api-user-full-access and assigned the permissions to the group.  Now I want to remove those permissions, and give the group access to my role by adding the following policy as an inline policy under Permissions.

```
{
    "Version": "2012-10-17",
    "Statement": {
        "Effect": "Allow",
        "Action": "sts:AssumeRole",
        "Resource": "arn:aws:iam::054218007579:role/AutomationFullAccess"
    }
}
```

Now that my group has access to assume the role, I need to define permissions on the role itself.  You would think it would be the mirror of the above policy; give it my group arn as the resource and be done with it.  You'd be wrong.  This policy ties a specific identity to the role; I can't do it by group because a group is not a specific identity.  Therefore, the only option I could find was to leave it open to the whole account and rely on group-side of the permissions to govern it.  This is a little bit scary, but much easier since I won't have to edit my role policy every time I add a group.

```
  {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::054218007579:root"
      },
      "Action": "sts:AssumeRole"
    }
```

But still, why not just add/remove people from the group and not do this?  Why mess with escalating permissions roles and such?  For what I'm doing now, it doesn't matter.  For a real person, assume roles means you have to purposefully escalate your permissions to a specific role before completing a task.  That's much safer than giving people carte blanche and turning them loose on the API or in the console.  It also gives real people a way to audit more cleanly.  Instead of looking through every event, they would just look at the escalations and track down the request that way.  It's potentially a lot less to dig through.  You can also force roles to use MFA if you want to.  You can't force a 3rd party contractor or your idiot friend who's helping you out to secure their ec2 credentials, but you can force them to adhere to your security policy before assuming your roles.

I implemented this, revoked the group-based permissions on the api-user-full-access group, and then tried it out by running a terraform apply.  It failed;
```
Failed to load state: AccessDenied: Access Denied
2018/08/01 12:14:41 [DEBUG] plugin: waiting for all plugin processes to complete...
	status code: 403, request id: 7C70031E0A8DCFFF, host id: o8hFGEJLTthz3TOsHTRVRjS3BtkK035yT0HLPn+yXP17jpNwYeZbL15VyH40b/XJlEux32lIMKI=
```

### Debugging assume roles and terraform
To debug this, I put terraform in debug mode with the TF_LOG environment variable:
```
export TF_LOG=debug
```
I ran it again and looked at the output.  It was getting permission denied when trying to list the contents of the s3 bucket where my state lives:
```
DEBUG: Response s3/ListObjects Details:
---[ RESPONSE ]--------------------------------------
HTTP/1.1 403 Forbidden
```
I decided to try using the AWS cli tools to do the same thing.  The debug log is quite a bit to look through and I couldn't seem to find where the assume role was happening, so I figured it would be cleaner if I ran the cli tools.  I previously installed the aws cli tools to create my Route53 reusable delegation set, so it was all set it.  I ran aws configure and made sure it was using my terraform secret and access keys.  I also added a section to my ~/.aws/config file that defined my assume role:
```
[profile prodProvision]
role_arn =  arn:aws:iam::054218007579:role/AutomationFullAccess
source_profile = default
```
Then I ran this to see if I could list my bucket contents.
```
aws s3api list-objects --bucket wyb-state-bucket --profile prodProvision
```
Oddly, this worked just fine:
```
{
    "Contents": [
        {
            "LastModified": "2018-08-01T16:30:26.000Z", 
            "ETag": "\"3050f75c3f87722f54f717cdd49da963\"", 
            "StorageClass": "STANDARD", 
            "Key": "tf_prod/wyb.tfstate", 
            "Owner": {
                "DisplayName": "mattdherrick", 
                "ID": "<some big id>"
            }, 
            "Size": 318
        }
    ]
}
```
Just to make sure it was assuming the role, I tried it without the --profile and it failed:
```
matt@ubuntu-tpad:~/Projects/wyb/terraform/vpc_public$ aws s3api list-objects --bucket wyb-state-bucket
An error occurred (AccessDenied) when calling the ListObjects operation: Access Denied
```

I messed around with this for a while, and ultimately the issue was a mistake in the group inline policy and the fact that terraform requires you to pass the assume role arn in with the backend configuration; it doesn't utilize the provider you defined.   If the mistake was my inline policy, Why did it work with aws cli?  I'm not sure.  But I'm guessing it has to do with the various ways credentials are managed in terraform and aws cli.  You can have environment variables and config files, and it could be that I had them set unintentionally.  Ultimately I was able to demonstrate that terraform and aws cli were failing, and that pointed me to the security policy in the role.  I'm going to leave this section in, even though it was my own negligence that caused this problem, because I think it's useful as a methodology for troubleshooting terraform.

With my arn in the backend config and my policies sorted, I was able to run a terraform init to reconfigure the backend.  But when it came time to run the actual provisioning, everything failed.  I originally put the assume_role statement in my provider, right under my references to my keys, but you need to define aws providers for your user and each separate role that you want to assume.  You can see that in providers.tf.  

Once you have multiple providers, you can't just let terraform use the default provider.  In my case, the user has no permissions to do anything.  You have to explicitly define the provider by it's alias when creating my resources.  This makes sense, because if you have very cleanly defined roles (instead of my sloppy ones that just allow everything), you'd need to use the correct provider for each type of resource you create.  Your s3 provisioning role for your s3 buckets, your ec2 provisioner for your instances, etc.

## A Dev Environment
This project is all about the process, and not the result.  I have no real goal or service to offer on washyobutt.com - at least not at the moment.  My mom suggested I try to sell the site to a bidet company.  I've been secretly hoping Flava Flav will see it and offer to hang out with me.  For the time being, I'm using it as an engineering exercise.  I'm trying to think through the whole process from a devops perspective, and design it like I would design a project for a real website.

I decided the next thing I'd do is create a development environment.  I'm going to use Vargrant for it.  Vagrant is a tool for building virtual machine environments, typically geared toward local workstations.  It's a tool that falls under the umbrella of "provisioning".  It's also owned by Hashicorp, so I know it's a good move from a devops perspective.  Hasicorp owns a bunch of sexy software that devops people use; Terraform, Vault, Consul, etc.  They're right up there with Atlassian in the devops software world, so I know my vagrant-based development environment would make all the heads nod at the next devops meetup I'll mark myself "interested" in on facebook and then not attend.

## Vagrant

Vagrant is pretty sweet.  It sits on top of a virtualization platform like VirtualBox (which is what I used because it's free) and lets you create, manage, and provision a virtual machine with a few commands.  Vagrant is managed by a single file called a Vagrantfile, where you define what your environment looks like.  The vagrant file gets created when you initialize your new VM.  I wanted to use my own vagrant file, so I wrote a wrapper script (setupDevEnv.sh) that installs virtual box and sets up the initial vagrant run.  

My goal was to spin up a dev environment from my project, and also work on the same project.  This drove a few design decisions.  First, I had to put the vagrant stuff in a directory outside of my project.  I chose ~/vagrant.  When vagrant starts, it creates files and such, and I didn't want people checking their vagrant shit into my project.  I also mounted my project directory into the vagrant machine by defining a synched_folder in my vagrantfile.  When you run the wrapper script, it gets the directory where the setupDevEnv.sh script is, and sets up a mount for you.  Since my setupDevEnv is in my project /devEnv directory, it mounts scriptdir/.., which should be the root of the wyb project.  

This is extra nice because I've been storing all my stuff in the wyb root/private directory, so that gets mounted as well.  I changed my wyb ec2 instance provisioning connection to use a keypair in in the private directory, and if you don't have one, my provisioning script creates one and dumps the public key into the terraform.tfvars file.  This means that the provisioning user is somewhat dynamic; each user who does the terraform apply could concievably provision with a different keypair.  I decided that this is okay; I don't want the terraform provisioner to be used for anything except provisioning.  My goal is to not require any access to the ec2 instance at all; I'm toying with deleting the provisioning key off the ec2 instance's authorized_keys files entirely at the end of the provisioning process.  My approach would be to have each (authorized) user upload their personal public key outside of terraform, and should they require SSh access, they'd have to manually attribute it to the ec2 instance.  That's a pain in the ass, but it's intentional, because I want all work done in the devops toolchain, and not by people ssh'ing into boxes to tinker around.

I also set up a provisioning script in my vagrantfile. The provisioning script, at this time, it's setting up terraform and creating the deployer keypair.  Eventually it'll do more, but I wanted to take some notes on it since I went through the exercise of verifying my terraform download with GPG.

## GPG
I'm downloading terraform programmatically, so I'm not able to look at the download page and see that it looks right and that I'm not getting a bunch of weird ssl errors that might indicate I'm downloading a compromised file.  I have no concerns about this actually happening, but I've seen gpg info on downloads all over the place and my attitude has always been both laissez faire, blase', and any other French words that imply general apathy.

GPG is based on trusting signatures.  At some point, you as the consumer need to decide to trust a gpg key.  What lengths you want to go to before acknowledging you trust is up to you.  The things I'm ultimately trusting are 1) The hashicorp website where they list their signature fingerprint, 2)My code where I store and verify the fingerprint in plain text, and 3) The key registry where I'm getting their gpg key from.  Ideally, you'd want Dave McJannet to hand you a notorized piece of paper with the public key written on it in his own blood, but even then, how do you know he's not really Larry Ellison in a mask?  Clearly, a DNA test is order.

Hashicorp gives you some extra files when you download Terraform. You get the download, a list of SHA sums for the download, and a .sig file.  The SHA sums file is signed with the .sig file and the hashicorp gpg public key.  The first step in verifying the download is to get the public key for hashicorp.  There are many key servers where people can upload signed keys.  GPG works on a system of trust where you sign keys you trust, and to make it easier people use key servers to track them.  Hashicorp lists their key id, so I get it from a key server with the id and then check the fingerprint.  Gpg has now stored the public key on my keyring within my vagrant vm.

At this point in the process, my provisioning script says:
```
gpg: WARNING: This key is not certified with a trusted signature!
gpg:          There is no indication that the signature belongs to the owner.
```
This appears because I haven't told GPG that I trust the key, or I don't trust someone who has trusted their key.  It's also saying "This is definitely a key claiming to be hashicorp but I have no way of proving that".  I could generate a key for Hashicorp and sign whatever the hell I want with it, but it doesn't mean I'm really Hashicorp.  I do trust it, because I checked the fingerprint that I got from a very official looking hashicorp website with a very official looking hashicorp ssl certificate, but I haven't explicitly told GPG that.  To trust a gpg key, you use the gpg edit-key command, but it's interactive and scripting around it in a provisioning process is a pain in the ass.  Therefore, I'm going to rely on my check of the fingerprint and just carry on with the process without explicitly telling gpg the key is trusted.

Next I'm going to check the signature of the SHA sums file.  Hashicorp doesn't sign their binary, they sign their checksum file.  The logic is that if the checksum file is signed, and the checksum of the binary matches the signed file, the binary is implicitly okay.  The gpg --verify command uses the .sig file and the gpg public key to check that the file hasn't been altered.  If the verify command returns sucessfully, I'll move to actually checking the binary.

You can use the shasum command by pointing it at the file directly, but it iterates through the whole thing and looks for the files in the local directory.  The SHA sums file contains the sums for all the terraform downloads, but I only care about the Linux binary.  It's dumb to download all the files just to get around the errors, so I used shasum to get the sum for the linux binary, and then made sure it was in the shasums file.

So, at a high level, the process is:
1) Get the appropriate public key
2) Check the public key fingerprint
3) Check the signature on the file containing the SHA256 checksums of the binary
4) Get the SHA256 signature of my downloaded file
5) Make sure my the checksum I got matches what's in the checksum file.
 
## Re-fixing My Assume Roles
When I was testing my Vagrant-ized development environment, I ran into more problems with terraform.  After some back and forth, I reconfigured it so I'm once-again using a single provider, which now has the keys defined and the assumerole statement.  I don't know why or how it was working with two providers, or why I thought that was a good idea. I'm consistently having problems managing my terraform credentials, and going to roles only complicated matters.  Terraform init requiring the keys separately from the rest of the config is a sticking point with me. 

I debating moving to using a credentials file instead of inline variables, but I didn't want to do that unless I had to.  The nice thing about credentials files is that awscli and terraform use the same files; ~/.aws/credentials.  I wanted to keep stuff out of my ~ directory as much as possible.  I could define a credentials file in my project /private dir and point terraform at them, but that's not much less complicated than my current approach.

## Back to Vagrant for some SSH'ing
As I started working with Vagrant, I realized I couldn't push to github.  Github was using my key in my home directory on my local laptop, so when I try to use it from my vagrant box, it fails.  The easy way to test your access to github is
```
ssh -T git@github.com
```
That allows you to sort your ssh shit out without needing to do a bunch of actual git work.  Git uses your local ssh config behind the scenes, which I really like.  To work around this I moved my keys to the ever-increasingly sensitive /private dir of my project, which I've locked down as much as I can while still being able to use it.

Usually ssh uses the ssh-agent, which does you a solid by adding the default keys to a keyring and trying them automatically when you attempt an ssh connection.  I debated using the ssh-add command to build a keyring on my vagrant box, but I decided not to do it.  Instead, I created a specific config for ssh connections to github which attempts to use the key /opt/wyb/private/wyb.  You'll recall that I'm mounting my github project into /opt/wyb on the vm.  That mount makes things very convienient.  I also generate a keypair for the user named wyb if they don't have one.

If I were adding a user to my project, I'd add them as a collaborator in github.  I don't need to worry about their ssh keys at all, really.  The new user would either upload the public half of the wyb keypair I created for them to their github account, or they'd need to get their key on the vagrant box somehow, and either add it to their keyring or update the .ssh/config section for github.  I don't really care; my primary goal was to make my personal git access work.

Once I got github working, I did a quick install of python.  Why no virtalenv? I clearly love it based on prevoius comments, but since this is an emphemeral vm I don't really want to put multiple python installs on it.  If I need to go to python3, I'll reconfigure vagrant to install python3 and destroy my existing vagrant environment.  I also grabbed pip and the python libraries I'm using; tweepy and configparser.  I threw the awscli tools on there as well, but I think I'm going to make the user set that up on their own.  It's worth noting at this point that a new user would have no access to my amazon account; they'd need me to create them a user with the appropriate access.

## Finishing Up the Dev Environment
I can now bring up a fully-working development environment by running setupDevenv.sh, followed by vagrant up, and then access it with vagrant ssh.  Once in there, I verified I can do a terraform destroy and a terraform apply.  In short, I'm well on my way to ephemeral environments from dev to production.  Granted I only have dev and production, but it still sounds cool to say.

If you look at provision.sh in my devEnv directory, you'll see I spent some time to write functions to check if all the necessary pieces are in place, and then summarized next steps for the user.  This will be a bit of a maintenance headache, but it's worth doing for a few reasons.  If I bring a new person on, I want them to know what they need to do to work on my project.  My provisioning file also serves as a central place to track all the requirements for my project.  If I keep my dev environment provisioning script updated, I'll never need to meander around trying to figure out what I had to do to make my shit work; it'll all be there right.  I need tweepy.  I need my twitter credentials.  I need my AWS keys in my terraform.tfvars.  It's all right there in my provisioning.sh file.  I don't need to document "getting started on your washyobutt.com adventure" at all, and I will consume my own record keeping periodically by tearing down and recreating my vagrant environment.  It's convience and an excuse not to document, all in one package.
