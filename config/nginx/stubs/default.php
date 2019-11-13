<?php if ('/phpinfo' == $_SERVER['REQUEST_URI']) {
    phpinfo();
} else { ?>
<!doctype html>
<html>
  <head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="robots" content="all, noindex, nofollow">
    <meta name="googlebot" content="all, noindex, nofollow">
    <title>Default Web Page</title>
    <link rel='stylesheet' type='text/css' href='//fonts.googleapis.com/css?family=Karla:400,700'>
    <link rel='stylesheet' type='text/css' href='//cdnjs.cloudflare.com/ajax/libs/animate.css/3.7.2/animate.min.css'>
    <link rel="icon" type="image/x-icon" href="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAB4AAAAeCAMAAAAM7l6QAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAABR1BMVEUAAADvnyLzniTooi7voCPvoCPwoST0nyDwoCPxnyL/qgDyoSLvnyTzoiP1ox/woSLqqivwoCPwoCPwnyLwnyPwoifxnyTwoCTwoCPwnyPuoiLwoSLwoCTvoCTxoSTzniTyoSjxnyLxnyP0myHmmRrvoCPxoCPjqhzwoCPwoCTwoSPwoCPwoCPvoCTvoCPwnyPwoCTvoSPwoCTxnyPwoCPwnyPxoCLvoSL/qivwoCPxoCPwoCPwoCPyoCPwoCPvoCPyoSLwoCPxnyLwoCPxnyLwoCPtniPwoCPunyLwoCTwoCPwoSTvoCX/nyDwoSPwoCTvoSPwoCPwoCLypibyniPwoCPwoSPyoSTtpCTwoCPwoCPrnSfwoCPwnyLwoCPwoCPwoCPxoCPynyDwoSTwoSPuoiLwoCLwnyTynSHwoCPwoCPwoCMAAACLgF6TAAAAa3RSTlMAcCoLg5N6GO4lAyZAFhlEDGapyGUhXe3sqB53VoFcFRNaWBcK5uUJ+tdXmflOXph5krpI97hZbwa3wv62O/2RTO81+ErZHdYtI/yHPgiaRl/7hhQ64eA5HPPyGjN4zMa7bihkqjxDiCfc25nru3cAAAABYktHRACIBR1IAAAACXBIWXMAAA3XAAAN1wFCKJt4AAAAB3RJTUUH4gwTEhI7xlnrsAAAAUdJREFUKM+d0ldbwjAUBuDDLhWlFES0roK7DnCBE7eAAgruiSBDz/+/Nym0pYXc+F2cpnmfNOdJCmCKzQb9Y3fQ6nTS6rD3sMtFq9ttjE3xcF5SeZ6UAc7T+3XfoDYa8vfdXgiIwaAYEizTw6LaSngE1UTCaqujYx3mJW6cNI16JgAmOYnX109Ng4xdiUIsZtpgZrab5+Yt+0cNW1hEXLKwouvyyirimiFxJSHAuqEbm4hbICSUuMrbUjIFO4i7e7riPqSSUrTryBEPQoeaYtqy9xHi8UnotKN4ZmH+nPpFRy95E2ay4MsRv2pr7hqyGR3zhUgR4CanNX9LDr0YKeS1qy6V6ePuvq0Pj/StXLJe+tMz1ZdXxu8G3jcSL0vh/eOzUvlictVPUmVy7ZukxuR6gKTOZFkhkf+7GhrNZoOt0Pr5bZkm/gC4WlyqqnyCMQAAACV0RVh0ZGF0ZTpjcmVhdGUAMjAxOC0xMi0xOVQxNzoxODo1OSswMTowMN/V1S0AAAAldEVYdGRhdGU6bW9kaWZ5ADIwMTgtMTItMTlUMTc6MTg6NTkrMDE6MDCuiG2RAAAAGXRFWHRTb2Z0d2FyZQB3d3cuaW5rc2NhcGUub3Jnm+48GgAAAABJRU5ErkJggg==">
    <style>
      body {
        margin: 0 auto;
        margin-top: 58px;
        max-width: 616px;
        padding: 0 16px;
        font-family: 'Karla', 'Helvetica Neue', sans-serif;
        font-size: 16px;
        font-weight: 400;
        line-height: 24px;
        color: rgba(0,0,0,0.87);
      }
      h1, h2, h3 {
        font-family: 'Karla', 'Helvetica Neue', sans-serif;
        font-weight: 700;
      }
      h1 {
        margin: 24px 0 16px 0;
        padding: 0 0 16px 0;
        border-bottom: 1px solid rgba(0,0,0,0.1);
        font-size: 32px;
        line-height: 36px;
      }
      h2 {
        margin: 24px 0 16px 0;
        padding: 0;
        font-size: 20px;
        line-height: 32px;
        color: rgba(0,0,0,0.54);
      }
      p {
        margin: 0;
        margin-bottom: 16px;
      }
      ol {
        margin: 0;

      }
      ol li {
        margin: 0;
        line-height: 24px;
        padding-left: 12px;
      }
      a {
        color: #039BE5;
        text-decoration: none;
      }
      a:hover {
          color: #1E90FF;
        text-decoration: none;
      }
      code {
        display: inline-block;
        padding: 3px 4px;
        background-color: #ECEFF1;
        border-radius: 3px;
        font-family: 'Roboto Mono',"Liberation Mono",Courier,monospace;
        font-size: 14px;
        line-height: 1;
      }
      .logo {
        display: block;
        text-align: center;
        margin-top: 58px;
        margin-bottom: 24px;
      }
      .text-info {
          color: #039BE5;
      }
      img {
        width: 180px;
      }
      @media screen and (max-width: 616px) {
        body {
         margin-top: 24px;
        }
        .logo  {
          margin: 0;
        }
      }
    </style>
  </head>
  <body>
      <div class="wrapper animated bounce">
        <h1>Welcome!</h1>
        <h2>Why am I seeing this?</h2>
        <p>There are a few reasons:</p>
        <ol>
            <li>This is the default page for your new site.</li>
            <li>This page used to test the web server configuration.</li>
            <li>Maybe you haven't uploaded your website yet.</li>
            <li>You may have deployed an empty directory.</li>
        </ol>
        <h2>How can I deploy my first app?</h2>
        <p>
            Please contact the <span class="text-info">hosting provider</span>
            or <span class="text-info">system administrator</span> to get help.
        </p>
      </div>
  </body>
</html>
<?php } ?>
