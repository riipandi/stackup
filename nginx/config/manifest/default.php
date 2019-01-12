<?php if ($_SERVER['REQUEST_URI'] == '/phpinfo') { phpinfo(); } else { ?>
<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="utf-8">
        <meta http-equiv="X-UA-Compatible" content="IE=edge">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <meta name="robots" content="all, noindex, nofollow">
        <meta name="googlebot" content="all, noindex, nofollow">
        <title>Default Web Page</title>
        <link rel="stylesheet" href="//fonts.googleapis.com/css?family=Kanit:200">
        <link rel="stylesheet" href="//cdnjs.cloudflare.com/ajax/libs/font-awesome/4.7.0/css/font-awesome.min.css" />
        <link rel="icon" type="image/x-icon" href="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAB4AAAAeCAMAAAAM7l6QAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAABR1BMVEUAAADvnyLzniTooi7voCPvoCPwoST0nyDwoCPxnyL/qgDyoSLvnyTzoiP1ox/woSLqqivwoCPwoCPwnyLwnyPwoifxnyTwoCTwoCPwnyPuoiLwoSLwoCTvoCTxoSTzniTyoSjxnyLxnyP0myHmmRrvoCPxoCPjqhzwoCPwoCTwoSPwoCPwoCPvoCTvoCPwnyPwoCTvoSPwoCTxnyPwoCPwnyPxoCLvoSL/qivwoCPxoCPwoCPwoCPyoCPwoCPvoCPyoSLwoCPxnyLwoCPxnyLwoCPtniPwoCPunyLwoCTwoCPwoSTvoCX/nyDwoSPwoCTvoSPwoCPwoCLypibyniPwoCPwoSPyoSTtpCTwoCPwoCPrnSfwoCPwnyLwoCPwoCPwoCPxoCPynyDwoSTwoSPuoiLwoCLwnyTynSHwoCPwoCPwoCMAAACLgF6TAAAAa3RSTlMAcCoLg5N6GO4lAyZAFhlEDGapyGUhXe3sqB53VoFcFRNaWBcK5uUJ+tdXmflOXph5krpI97hZbwa3wv62O/2RTO81+ErZHdYtI/yHPgiaRl/7hhQ64eA5HPPyGjN4zMa7bihkqjxDiCfc25nru3cAAAABYktHRACIBR1IAAAACXBIWXMAAA3XAAAN1wFCKJt4AAAAB3RJTUUH4gwTEhI7xlnrsAAAAUdJREFUKM+d0ldbwjAUBuDDLhWlFES0roK7DnCBE7eAAgruiSBDz/+/Nym0pYXc+F2cpnmfNOdJCmCKzQb9Y3fQ6nTS6rD3sMtFq9ttjE3xcF5SeZ6UAc7T+3XfoDYa8vfdXgiIwaAYEizTw6LaSngE1UTCaqujYx3mJW6cNI16JgAmOYnX109Ng4xdiUIsZtpgZrab5+Yt+0cNW1hEXLKwouvyyirimiFxJSHAuqEbm4hbICSUuMrbUjIFO4i7e7riPqSSUrTryBEPQoeaYtqy9xHi8UnotKN4ZmH+nPpFRy95E2ay4MsRv2pr7hqyGR3zhUgR4CanNX9LDr0YKeS1qy6V6ePuvq0Pj/StXLJe+tMz1ZdXxu8G3jcSL0vh/eOzUvlictVPUmVy7ZukxuR6gKTOZFkhkf+7GhrNZoOt0Pr5bZkm/gC4WlyqqnyCMQAAACV0RVh0ZGF0ZTpjcmVhdGUAMjAxOC0xMi0xOVQxNzoxODo1OSswMTowMN/V1S0AAAAldEVYdGRhdGU6bW9kaWZ5ADIwMTgtMTItMTlUMTc6MTg6NTkrMDE6MDCuiG2RAAAAGXRFWHRTb2Z0d2FyZQB3d3cuaW5rc2NhcGUub3Jnm+48GgAAAABJRU5ErkJggg==">
        <!--[if lt IE 9]>
            <script src="//oss.maxcdn.com/html5shiv/3.7.3/html5shiv.min.js"></script>
            <script src="//oss.maxcdn.com/respond/1.4.2/respond.min.js"></script>
        <![endif]-->
        <style>
            *{-webkit-box-sizing:border-box;box-sizing:border-box}
            body{padding:0;margin:0}
            #notfound{position:relative;height:100vh}
            #notfound .notfound{position:absolute;left:50%;top:50%;-webkit-transform:translate(-50%,-50%);-ms-transform:translate(-50%,-50%);transform:translate(-50%,-50%)}
            .notfound{max-width:767px;width:100%;line-height:1.4;text-align:center;padding:15px}
            .notfound .notfound-404{position:relative;height:220px}
            .notfound .notfound-404 h1{font-family:'Kanit',sans-serif;position:absolute;left:50%;top:50%;-webkit-transform:translate(-50%,-50%);-ms-transform:translate(-50%,-50%);transform:translate(-50%,-50%);font-size:186px;font-weight:200;margin:0;background:linear-gradient(130deg,#ffa34f,#ff6f68);color:transparent;-webkit-background-clip:text;background-clip:text;text-transform:capitalize}
            .notfound h2{font-family:'Kanit',sans-serif;font-size:33px;font-weight:200;text-transform:uppercase;margin-top:0;margin-bottom:25px;letter-spacing:3px}
            .notfound p{font-family:'Kanit',sans-serif;font-size:16px;font-weight:200;margin-top:0;margin-bottom:25px;line-height:1.8em}
            .notfound a{font-family:'Kanit',sans-serif;color:#ff6f68;font-weight:200;text-decoration:none;border-bottom:1px dashed #ff6f68;border-radius:2px}
            .notfound-social>a{display:inline-block;height:40px;line-height:40px;width:40px;font-size:14px;color:#ff6f68;border:1px solid #efefef;border-radius:50%;margin:6px;-webkit-transition:.2s all;transition:.2s all}
            .notfound-social>a:hover{color:#fff;background-color:#ff6f68;border-color:#ff6f68}
            @media only screen and (max-width: 480px) {
            .notfound .notfound-404{position:relative;height:168px}
            .notfound .notfound-404 h1{font-size:142px}
            .notfound h2{font-size:22px}
            }
        </style>
    </head>
    <body>
        <div id="notfound">
            <div class="notfound">
                <div class="notfound-404">
                    <h1>Hello!</h1>
                </div>
                <h2>Welcome to our new website.</h2>
                <p>
                    This is the default page for <?=$_SERVER['HTTP_HOST'];?>.
                    This page used to test the correct operation of the web server
                    installation and we are using PHP v<?=(float)phpversion();?> as
                    default interpreter. If you can read this page, it means that the
                    web server installed and working properly.
                </p>
                <div class="notfound-social">
                    <a href="//github.com/riipandi"><i class="fa fa-github"></i></a>
                    <a href="//twitter.com/riipandi"><i class="fa fa-twitter"></i></a>
                    <a href="//instagram.com/riipandi"><i class="fa fa-instagram"></i></a>
                </div>
            </div>
        </div>
    </body>
</html>
<?php } ?>
