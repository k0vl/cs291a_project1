# Project 1 Template

## Clone


## Develop and Test

Edit the file function.rb to provide the necessary implementation.

    ruby function.rb

## Deploy

    ./deploy AWS_ACCOUNT_NAME

## Teardown (if necessary)

    ./teardown AWS_ACCOUNT_NAME

Note: Don't teardown after you've submitted your project. We'll clean
everything up when the project is done being graded.

## Project 1 Questions

* On average, how many successful requests can ab complete to /token in 8 seconds with various power-of-two concurrency levels between 1 and 256?

  concurrency 1: 52/10s ≈ 42/8s\
  concurrency 2: 107/10s ≈ 86/8s\
  concurrency 4: 204/10s ≈ 163/8s\
  concurrency 8: 402/10s ≈ 322/8s\
  concurrency 16: 798/10s ≈ 638/8s\
  concurrency 32: 1547/10s ≈ 1238/8s\
  concurrency 64: 3097/10s ≈ 2478/8s\
  concurrency 128: 5993/10s ≈ 4794/8s\
  concurrency 256: 10376/10s ≈ 8301/8s

* Using data you’ve collected, describe how this service’s performance compares to that of your static webpage from Project 0 (remeasure those results if necessary).

  This service is about 10 times slower than GitHub pages at each concurrency level. However, my machine only hit the CPU bottleneck at 256 concurrent connections, at which point AWS is servicing 25% less connections compared to GitHub pages.
  
* What do you suspect accounts for the difference in performance between GitHub pages and your AWS Lambda web service?

  AWS Lambda takes a significant amount of time to spin up new lambda instances initially, and from the Cloudwatch logs I see ~200 lambda instances worked on the final test. Assuming each cold start takes 0.2 seconds, in total it would take 40 thread-seconds, which is ~1% of 4088 total thread-seconds. ((0.2s * 200) / ((2^9 -1) * 8s))  This is negligible.
  
  Then there is Ruby execution, which is slow. From the Cloudwatch logs, each instance was handling 16-17 requests per second during the middle of the test. 16 * 8 * 200 = 25600 requests at -c 256, so this account's for 8301/25600 ≈ 1/3 of the response time.
  
  API Gateway and AWS network probably also contributed, although they cannot be measured easily. 
  
  Lastly, some of the difference may be due to the fact that it wasn't a static page, and so it cannot be cached by, say, CDN. 
