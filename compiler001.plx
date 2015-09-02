$input = ("
 sign = #32768
 a = 10
 b = 11
 test = a & sign
 test !{
  ascale = ascale + #1
  a = a << #1
  test = a & sign
 }
 test = b & sign
 test !{
  bscale = bscale + #1
  b = b << #1
  test = b & sign
 }
 totalscale = bscale - ascale
 14 = totalscale
 bit = #15
 bit {
 test = b & sign
 test !{
  b = b << #1
  bit = bit + #1
  test = b & sign
 }
 test = a & sign
 test !{
  a = a << #1
  bit = bit - #1
  test = a & sign
 }
 test = a - b
 test = test & sign
 test [
  b = b >> #1
  bit = bit - #1
 ]
 a = a - b
 shiftedbit = #1 << bit
 test = bit & sign
 test [
  bit = #0
 ]
 test ![
  c = c + shiftedbit
 ]
 15 = c
 a ![
  bit = #0
 ]
 }
 #1 {
 }
");
@input = split(/\n/,$input);
for(0..~~@input){
 $input[$_] =~ s/\s+//g;
 ($program[$_][1],$program[$_][0]) = split(/=/, $input[$_], 2);
}
while($pointer < ~~@program){
$var = $program[$pointer][0] =~ /(\+)|(\-)|(<<)|(>>)|(:)|(\%)|(\&)/;
if($var){
 $a = $program[$pointer][1];
 $b = $`;
 $c = $';
 $op = $&;
 if($op eq "+"){
  splice(@program,$pointer,1,([$b,4],[$c,5],[4,$a]));
 }
 if($op eq "-"){
  splice(@program,$pointer,1,([$b,4],[$c,5],[5,$a]));
 }
 if($op eq "<<"){
  splice(@program,$pointer,1,([$b,6],[$c,7],[6,$a]));
 }
 if($op eq ">>"){
  splice(@program,$pointer,1,([$b,6],[$c,7],[7,$a]));
 }
 if($op eq "&"){
  splice(@program,$pointer,1,([$b,8],[$c,9],[8,$a]));
 }
 if($op eq "%"){
  splice(@program,$pointer,1,(["#32768",9],[$c,5],[$b,4],[$b,8],["","8!{"],[5,8],[5,4],["","}"],[4,$a]));
 }
 if($op eq ":"){
  if($arrayQ{$b} < 1){
   push(@arraylist, $b);
  }
  $arrayQ{$b} = 1;
  splice(@program,$pointer,1,([$c,6],["ARRAY_DELTA",7],[6,4],[$b,5],[4,12],[13,$a]));
 }
}
$var2 = $program[$pointer][1] =~ /!*((\{)|(\[)|(\})|(\])|(:))/;
if($var2){
 $c = $program[$pointer][0];
 $a = $cond = $`;
 $bracket = $&;
 $b = $';
 if($bracket eq ":"){
  if($arrayQ{$a} < 1){
   push(@arraylist, $a);
  }
  $arrayQ{$a} = 1;
  splice(@program,$pointer,1,([$b,6],["ARRAY_DELTA",7],[6,4],[$a,5],[4,12],[$c,13]));
 }
 if($bracket eq "["){
  push(@ifstack,$pointer);
  splice(@program,$pointer,1,(["#" . ($pointer*2+24),3],["IF$pointer",2],[$cond,1],[1,0]));
 }
 if($bracket eq "!["){
  push(@ifstack,$pointer);
  splice(@program,$pointer,1,(["#" . ($pointer*2+24),2],["IF$pointer",3],[$cond,1],[1,0]));
 }
 if($bracket eq "]"){
  splice(@program,$pointer,1);
  $start = pop(@ifstack);
  $program[$start+1][0] = "#" . ($pointer*2+16);
  $pointer--;
 }
 if($bracket eq "{"){
  push(@whilestack,$pointer);
  splice(@program,$pointer,1,(["#" . ($pointer*2+24),3],["WHILE$pointer",2],[$cond,1],[1,0]));
 }
 if($bracket eq "!{"){
  push(@whilestack,$pointer);
  splice(@program,$pointer,1,(["#" . ($pointer*2+24),2],["WHILE$pointer",3],[$cond,1],[1,0]));
 }
 if($bracket eq "}"){
  $start = pop(@whilestack);
  splice(@program,$pointer,1,(["#" . ($start*2+16),0]));
  $program[$start+1][0] = "#" . ($pointer*2+18);
  $pointer--;
 }
}
if($program[$pointer][0] eq "" && $program[$pointer][1] eq ""){
 splice(@program,$pointer,1);
 $pointer--;
}
$pointer++;
}
for(0..~~@program){
 print "$program[$_][0] $program[$_][1]\n";
}


$exactaddress = 16;
$varaddress = ~~@program*2+16;
for($pointer = 0; $pointer < ~~@program; $pointer++){
 for($half = 0; $half <= 1; $half++){
  $curvar = $program[$pointer][$half];
  if($curvar eq ""){$curvar = 0}
  if($curvar == 0 && $curvar ne "0"){
   $curvar =~ s/\#//g;
   if($varlocs{$curvar} == 0){
    $varlocs{$curvar} = $varaddress++;
    $binary[$varlocs{$curvar}] = int($curvar);
   }
   $program[$pointer][$half] = $varlocs{$curvar};
  }
  $binary[$exactaddress] = $program[$pointer][$half];
  $exactaddress++;
 }
}

for($i = 0; $i < ~~@arraylist; $i++){
 $curvar = $arraylist[$i];
 $curvar =~ s/\#//g;
 $binary[$varlocs{$curvar}] = $varaddress++;
}

$arraydelta = 0;
while(2**$arraydelta < ~~@arraylist){
 $arraydelta++;
}
$binary[$varlocs{"ARRAY_DELTA"}] = $arraydelta;

for(0..~~@binary-1){
 $binary[$_] = int($binary[$_]);
}

print"-----\n";
for(0..~~@binary-1){
 printf("%x ",$binary[$_]);
}
