./burnSerial -x XD070100 0 || exit 1
xrun --io hello.xe
if [ $? -eq 79 ]
then
  echo "Test passed"
else
  echo "@@@@@@@@@@@@@@@@@@@@@@ TEST FAILED @@@@@@@@@@@@@@@@@@@@@@@@"
fi
