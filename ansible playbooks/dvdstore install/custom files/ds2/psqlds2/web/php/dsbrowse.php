
<?php
/*  
 * DVD Store Browse PHP Page - dsbrowse.php
 *
 * Copyright (C) 2005 Dell, Inc. <dave_jaffe@dell.com> and <todd_muirhead@dell.com>
 * Copyright (C) 2011 VMware, Inc. <jshah@vmware.com> and <tmuirhead@vmware.com>
 *
 * Browses PostgreSQL DVD store by author, title, or category
 *
 * Last Updated 2/1/11
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/ 

include("dscommon.inc");

ds_html_header("DVD Store Browse Page");

$customerid = $_REQUEST["customerid"];
$browsetype = isset($_REQUEST["browsetype"]) ? $_REQUEST["browsetype"] : NULL;
$browse_title = isset($_REQUEST["browse_title"]) ? $_REQUEST["browse_title"] : NULL;
$browse_actor = isset($_REQUEST["browse_actor"]) ? $_REQUEST["browse_actor"] : NULL;
$browse_category = isset($_REQUEST["browse_category"]) ? $_REQUEST["browse_category"] : NULL;
$limit_num = isset($_REQUEST["limit_num"]) ? $_REQUEST["limit_num"] : NULL;
$selected_item = isset($_REQUEST["selected_item"]) ? $_REQUEST["selected_item"] : NULL;
$item = isset($_REQUEST["item"]) ? $_REQUEST["item"] : NULL;
// $selected_item = $_REQUEST["selected_item"];
// $item = $_REQUEST["item"];

if (empty($customerid))
  {
  echo "<H2>You have not logged in - Please click below to Login to DVD Store</H2>\n";
  echo "<FORM ACTION='./dslogin.php' METHOD=GET>\n";
  echo "<INPUT TYPE=SUBMIT VALUE='Login'>\n";
  echo "</FORM>\n";
  ds_html_footer();
  exit;
  }

if (isset($selected_item))  // Add new selected items to shopping cart (item[] array)
  {
  $n_items = count($item);
  for ($i=0; $i<count($selected_item); $i++) $item[$n_items + $i] = $selected_item[$i];
  }

echo "<H2>Select Type of Search</H2>\n";

echo "<FORM ACTION='./dsbrowse.php' METHOD='GET'>\n";

echo "<INPUT NAME='browsetype' TYPE=RADIO VALUE='title'"; if($browsetype == 'title') echo "CHECKED"; 
echo ">Title  <INPUT NAME='browse_title' VALUE='$browse_title' TYPE=TEXT SIZE=15> <BR>\n";
echo "<INPUT NAME='browsetype' TYPE=RADIO VALUE='actor'"; if($browsetype == 'actor') echo "CHECKED"; 
echo ">Actor  <INPUT NAME='browse_actor' VALUE='$browse_actor' TYPE=TEXT SIZE=15> <BR>\n";
echo "<INPUT NAME='browsetype' TYPE=RADIO VALUE='category'"; if($browsetype == 'category') echo "CHECKED"; echo ">Category\n";

$categories = array("Action", "Animation", "Children", "Classics", "Comedy", "Documentary", "Drama", "Family", "Foreign", 
  "Games", "Horror", "Music", "New", "Sci-Fi", "Sports", "Travel");

echo "<SELECT NAME='browse_category'>\n";
for ($i=0; $i<count($categories); $i++)
  {
  $j=$i+1;
  if ($j == $browse_category)
    {echo "  <OPTION VALUE=$j SELECTED>$categories[$i]</OPTION>\n";}
  else
    {echo "  <OPTION VALUE=$j>$categories[$i]</OPTION>\n";}
  }
echo "</SELECT><BR>\n";

echo "Number of search results to return\n";
echo "<SELECT NAME='limit_num'>\n";
for ($i=1; $i<11; $i++)
  {
  if ($i == $limit_num)
    {echo "  <OPTION VALUE=$i SELECTED>$i</OPTION>\n";}
  else
    {echo "  <OPTION VALUE=$i>$i</OPTION>\n";}
  }
echo "</SELECT><BR>\n";

echo "<INPUT TYPE=HIDDEN NAME=customerid VALUE='$customerid'>\n";
for ($i=0; $i<count($item); $i++) echo "<INPUT TYPE=HIDDEN NAME='item[]' VALUE=$item[$i]>\n";
echo "<INPUT TYPE=SUBMIT VALUE='Search'>\n";
echo "</FORM>\n";

if (!empty($browsetype))
  {
  if (!($link_id = pg_pconnect($connstr))) die(pg_last_error());

  switch ($browsetype)
    {
    case "title":
      $browse_title_q = str_replace(" ","&",$browse_title);
      $browse_query = "select * from PRODUCTS where to_tsvector('simple',TITLE) @@ to_tsquery('" . $browse_title_q . "') LIMIT $limit_num;\n";
      break;
    case "actor":
      $browse_actor_q = str_replace(" ","&",$browse_actor);
      $browse_query = "select * from PRODUCTS where to_tsvector('simple',ACTOR) @@ to_tsquery('" . pg_escape_string($browse_actor_q) . "') LIMIT $limit_num;\n";
      break;
    case "category":
      $browse_query = "select * from PRODUCTS where CATEGORY = $browse_category and SPECIAL=1 LIMIT $limit_num;\n";
      break;
    }

  $browse_result = pg_query($browse_query);

  if (pg_num_rows($browse_result) == 0)
    {
    echo "<H2>No DVDs Found</H2>\n";
    }
  else
    {
    echo "<BR>\n";
    echo "<H2>Search Results</H2>\n";
    echo "<FORM ACTION='./dsbrowse.php' METHOD=GET>\n";
    echo "<TABLE border=2>\n";
    echo "<TR>\n";
    echo "<TH>Add to Shopping Cart</TH>\n";
    echo "<TH>Title</TH>\n";
    echo "<TH>Actor</TH>\n";
    echo "<TH>Price</TH>\n";
    echo "</TR>\n";
    while ($browse_result_row = pg_fetch_row($browse_result))
      {
      echo " <TR>\n";
      echo "<TD><INPUT NAME=selected_item[] TYPE=CHECKBOX VALUE=$browse_result_row[0]></TD>\n";
      echo "<TD>$browse_result_row[2]</TD>\n";
      echo "<TD>$browse_result_row[3]</TD>\n";
      echo "<TD>$browse_result_row[4]</TD>\n";
      echo "</TR>\n";
      }      
    pg_free_result($browse_result);
    echo "</TABLE>\n";
    echo "<BR>\n";

    echo "<INPUT TYPE=HIDDEN NAME=customerid VALUE='$customerid'>\n";
    for ($i=0; $i<count($item); $i++) echo "<INPUT TYPE=HIDDEN NAME='item[]' VALUE=$item[$i]>\n";
    echo "<INPUT TYPE=SUBMIT VALUE='Update Shopping Cart'>\n";
    echo "</FORM>\n";
    }
  pg_close($link_id);
  }

if (isset($item))  // Show shopping cart
  {
  echo "<H2>Shopping Cart</H2>\n";
  echo "<FORM ACTION='./dspurchase.php' METHOD='GET'>\n";
  echo "<TABLE border=2>\n";
  echo "<TR>\n";
  echo "<TH>Item</TH>\n";
  echo "<TH>Title</TH>\n";
  echo "</TR>\n";
  if (!($link_id = pg_pconnect($connstr))) die(pg_last_error());
  for ($i=0; $i<count($item); $i++) 
    {
    $j=$i+1;
    $query = "select TITLE from PRODUCTS where PROD_ID=$item[$i];";
    $result = pg_query($query);
    $result_row = pg_fetch_row($result);
    $title = $result_row[0];
    echo "<TD>$j</TD><TD>$title</TD></TR>\n";
    }
  pg_free_result($result);
  echo "</TABLE>\n";
  echo "<BR>\n";
  for ($i=0; $i<count($item); $i++) echo "<INPUT TYPE=HIDDEN NAME='item[]' VALUE=$item[$i]>\n";
  echo "<INPUT TYPE=HIDDEN NAME=customerid VALUE='$customerid'>\n";
  echo "<INPUT TYPE=SUBMIT VALUE='Checkout'>\n";
  echo "</FORM>\n";
  pg_close($link_id);
  }
ds_html_footer();
?>
