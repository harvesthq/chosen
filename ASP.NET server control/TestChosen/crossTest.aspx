<%@ Page Language="C#" AutoEventWireup="true" CodeFile="crossTest.aspx.cs" Inherits="crossTest" %>

<!DOCTYPE html>
<html>
<head>
<style> 
#mdiv
{
width:25px;
height:25px;
background-color:red;
border:1px solid black;
}
.mdiv
{
height:25px;
width:2px;
margin-left:12px;
background-color:black;
transform: rotate(45deg);
-ms-transform: rotate(45deg); /* IE 9 */
-webkit-transform: rotate(45deg); /* Safari and Chrome */
Z-index:1;

}
.md
{
height:25px;
width:2px;

background-color:black;
transform: rotate(90deg);
-ms-transform: rotate(90deg); /* IE 9 */
-webkit-transform: rotate(90deg); /* Safari and Chrome */
Z-index:2;

}
</style>
</head>
<body>

<div id="mdiv" >
<div class="mdiv">
<div class="md">
</div>
</div>

<div>

</body>
