package rtmpClient.utils
{
	public class BigInt
	{
		////////////////////////////////////////////////////////////////////////////////////////
		// Big Integer Library v. 5.4
		// Created 2000, last modified 2009
		// Leemon Baird
		// www.leemon.com
		//
		// Ported to ActionScript by Ian Peters (ian at ianpeters.net), April 2011 
		//
		// See original .js Implementation at www.leemon.com for version history, and for further
		// documentation.
		//
		// Note that as this is being run in an interpreted language, don't expect this to be fast.
		// For example, a diffie-hellman implementation (Oakley group 2) with 1024-bit secrets 
		// takes around 15-20s to complete.
		//
		// This file is public domain.   You can use it for any purpose without restriction.
		// I do not guarantee that it is correct, so use it at your own risk.  If you use 
		// it for something interesting, I'd appreciate hearing about it.  If you find 
		// any bugs or make any improvements, I'd appreciate hearing about those too.
		// It would also be nice if my name and URL were left in the comments.  But none 
		// of that is required.
		//
		// This code defines a type-safe bigInt library for arbitrary-precision integers.
		// 
		// Public methods handle a BigInt type. In some cases these have been modified to work
		// correctly with the BigInt type, but most are wrappers around a private method
		// which handles the bigint as an array of integers storing the value in chunks of bpe bits, 
		// little endian (buff[0] is the least significant word).
		//
		// Negative bigInts are stored two's complement.  Almost all the functions treat
		// bigInts as nonnegative.  The few that view them as two's complement say so
		// in their comments.  Some functions assume their parameters have at least one 
		// leading zero element. 
		//
		// Functions with an underscore at the end of the name are private and put
		// their answer into one of the arrays passed in, and have unpredictable behavior 
		// in case of overflow, so the caller must make sure the arrays are big enough to 
		// hold the answer.  But the average user should never have to call any of the 
		// underscored functions.  Each important underscored function has a wrapper function 
		// of the same name without the underscore that takes care of the details for you.  
		// For each underscored function where a parameter is modified, that same variable 
		// must not be used as another argument too.  So, you cannot square x by doing 
		// multMod_(x,x,n).  You must use squareMod_(x,n) instead, or do y=dup(x); multMod_(x,y,n).
		// Or simply use the multMod(x,x,n) function without the underscore, where
		// such issues never arise, because non-underscored functions never change
		// their parameters; they always allocate new memory for the answer that is returned.
		//
		// These functions are designed to avoid frequent dynamic memory allocation in the inner loop.
		// For most functions, if it needs a BigInt as a local variable it will actually use
		// a global, and will only allocate to it only when it's not the right size.  This ensures
		// that when a function is called repeatedly with same-sized parameters, it only allocates
		// memory on the first call.
		//
		// Note that for cryptographic purposes, the calls to Math.random() must 
		// be replaced with calls to a better pseudorandom number generator.
		// 
		//
		// The following functions are based on algorithms from the _Handbook of Applied Cryptography_
		//    powMod_()           = algorithm 14.94, Montgomery exponentiation
		//    eGCD_,inverseMod_() = algorithm 14.61, Binary extended GCD_
		//    GCD_()              = algorothm 14.57, Lehmer's algorithm
		//    mont_()             = algorithm 14.36, Montgomery multiplication
		//    divide_()           = algorithm 14.20  Multiple-precision division
		//    squareMod_()        = algorithm 14.16  Multiple-precision squaring
		//    randTruePrime_()    = algorithm  4.62, Maurer's algorithm
		//    millerRabin()       = algorithm  4.24, Miller-Rabin algorithm
		//
		////////////////////////////////////////////////////////////////////////////////////////
		
		//globals
		private static var bpe:int=0;         //bits stored per array element
		private static var mask:int=0;        //AND this with an array element to chop it down to bpe bits
		private static var radix:int=1;  //equals 2^bpe.  A single 1 bit to the left of the last bit of mask.
		
		//the digits for converting to different bases
		private static var digitsStr:String='0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz_=!@#$%^&*()[]{}|;:,.<>/?`~ \\\'\"+-';
		//the following global variables are scratchpad memory to 
		//reduce dynamic memory allocation in the inner loop
		private static var t:Array=new Array(0);
		private static var _b:BigInt=new BigInt();
		private static var ss:Array=t;       //used in mult_()
		private static var s0:Array=t;       //used in multMod_(), squareMod_() 
		private static var s1:Array=t;       //used in powMod_(), multMod_(), squareMod_() 
		private static var s2:Array=t;       //used in powMod_(), multMod_()
		private static var s3:Array=t;       //used in powMod_()
		private static var s4:Array=t; private static var s5:Array=t; //used in mod_()
		private static var s6:Array=t;       //used in bigInt2str()
		private static var s7:Array=t;       //used in powMod_()
		private static var T:Array=t;        //used in GCD_()
		private static var sa:Array=t;       //used in mont_()
		private static var mr_x1:Array=t; private static var mr_r:Array=t; private static var mr_a:Array=t;                                      //used in millerRabin()
		private static var eg_v:Array=t; private static var eg_u:Array=t; private static var eg_A:Array=t; private static var eg_B:Array=t; private static var eg_C:Array=t; private static var eg_D:Array=t;               //used in eGCD_(), inverseMod_()
		private static var md_q1:Array=t; private static var md_q2:Array=t; private static var md_q3:Array=t; private static var md_r:Array=t; private static var md_r1:Array=t; private static var md_r2:Array=t; private static var md_tt:Array=t; //used in mod_()
		private static var primes:Array=t; private static var pows:Array=t; private static var s_i:Array=t; private static var s_i2:Array=t; private static var s_R:Array=t; private static var s_rm:Array=t; private static var s_q:Array=t; private static var s_n1:Array=t; 
		private static var s_a:Array=t; private static var s_r2:Array=t; private static var s_n:Array=t; private static var s_b:Array=t; private static var s_d:Array=t; private static var s_x1:Array=t; private static var s_x2:Array=t; private static var s_aa:Array=t; //used in randTruePrime_()
		private static var rpprb:Array=t; //used in randProbPrimeRounds() (which also uses "primes")
		private static var one:BigInt=int2bigInt(1,1,1);     //constant used in powMod_()
		
		private static var isInit:Boolean = false;
		
		private var val:Array;
		
		public function BigInt(a:Array=null){
			init();
			if(a==null) val = new Array(0);
			else val = a;
		}
		private function init():void{
			if(!isInit){
				isInit=true;
				//initialize the global variables
				for (bpe=0; (1<<(bpe+1)) > (1<<bpe); bpe++){};  //bpe=number of bits in the mantissa on this platform
				bpe>>=1;                   //bpe=number of bits in one element of the array representing the bigInt
				mask=(1<<bpe)-1;           //AND the mask with an integer to get its bpe least significant bits
				radix=mask+1;              //2^bpe.  a single 1 bit to the left of the first bit of mask
				one=int2bigInt(1,1,1);     //constant used in powMod_()
				
			}
		}
		
		////////////////////////////////////////////////////////////////////////////////////////
		
		
		//return array of all primes less than integer n
		public static  function findPrimes(n:int):Array {
			var i:int,s:Array,p:int,ans:Array;
			s=new Array(n);
			for (i=0;i<n;i++)
				s[i]=0;
			s[0]=2;
			p=0;    //first p elements of s are primes, the rest are a sieve
			for(;s[p]<n;) {                  //s[p] is the pth prime
				for(i=s[p]*s[p]; i<n; i+=s[p]) //mark multiples of s[p]
					s[i]=1;
				p++;
				s[p]=s[p-1]+1;
				for(; s[p]<n && s[s[p]]; s[p]++){}; //find next prime (where s[p]==0)
			}
			ans=new Array(p);
			for(i=0;i<p;i++)
				ans[i]=s[i];
			return ans;
		}
		
		
		//does a single round of Miller-Rabin base b consider x to be a possible prime?
		//x is a bigInt, and b is an integer, with b<x
		public static function millerRabinInt(x:BigInt,b:int):Boolean {
			if(x==null) return false;
			return millerRabinInt_(x.val, b);
		}
		
		private static function millerRabinInt_(x:Array,b:int):Boolean {
			if (mr_x1.length!=x.length) {
				mr_x1=dup_(x);
				mr_r=dup_(x);
				mr_a=dup_(x);
			}
			
			copyInt_(mr_a.val,b);
			return millerRabin_(x,mr_a);
		}
		
		//does a single round of Miller-Rabin base b consider x to be a possible prime?
		//x and b are bigInts with b<x
		public static function millerRabin(x:BigInt,b:BigInt):Boolean {
			if(x==null||b==null) return false;
			return millerRabin_(x.val,b.val);
		}
		private static function millerRabin_(x:Array,b:Array):Boolean {
			var i:int,j:int,k:int,s:int;
			
			if (mr_x1.length!=x.length) {
				mr_x1=dup_(x);
				mr_r=dup_(x);
				mr_a=dup_(x);
			}
			
			copy_(mr_a,b);
			copy_(mr_r,x);
			copy_(mr_x1,x);
			
			addInt_(mr_r.val,-1);
			addInt_(mr_x1.val,-1);
			
			//s=the highest power of two that divides mr_r
			k=0;
			for (i=0;i<mr_r.val.length;i++)
				for (j=1;j<mask;j<<=1)
					if (x.val[i] & j) {
						s=(k<mr_r.val.length+bpe ? k : 0); 
						i=mr_r.val.length;
						j=mask;
					} else
						k++;
			
			if (s)                
				rightShift_(mr_r.val,s);
			
			powMod_(mr_a.val,mr_r.val,x.val);
			
			if (!equalsInt_(mr_a,1) && !equals_(mr_a,mr_x1)) {
				j=1;
				while (j<=s-1 && !equals_(mr_a,mr_x1)) {
					squareMod_(mr_a.val,x.val);
					if (equalsInt_(mr_a,1)) {
						return false;
					}
					j++;
				}
				if (!equals_(mr_a,mr_x1)) {
					return false;
				}
			}
			return true;  
		}
		
		//returns how many bits long the bigInt is, not counting leading zeros.
		public static function bitSize(x:BigInt):int {
			return bitSize_(x.val);
		}
		public static function bitSize_(x:Array):int {
			var j:int,z:int,w:int;
			for (j=x.length-1; (x[j]==0) && (j>0); j--){};
			for (z=0,w=x[j]; w; (w>>=1),z++){};
			z+=bpe*j;
			return z;
		}
		
		//return a copy of x with at least n elements, adding leading zeros if needed
		public static function expand(x:BigInt,n:int):BigInt {
			var ans:BigInt=int2bigInt(0,(x.val.length>n ? x.val.length : n)*bpe,0);
			copy_(ans.val,x.val);
			return ans;
		}
		
		
		//return a k-bit true random prime using Maurer's algorithm.
		public static function randTruePrime(k:int):BigInt {
			var ans:BigInt=int2bigInt(0,k,0);
			randTruePrime_(ans.val,k);
			return trim(ans,1);
		}
		
		
		//return a k-bit random probable prime with probability of error < 2^-80
		public static function randProbPrime(k:int):BigInt {
			if (k>=600) return randProbPrimeRounds(k,2); //numbers from HAC table 4.3
			if (k>=550) return randProbPrimeRounds(k,4);
			if (k>=500) return randProbPrimeRounds(k,5);
			if (k>=400) return randProbPrimeRounds(k,6);
			if (k>=350) return randProbPrimeRounds(k,7);
			if (k>=300) return randProbPrimeRounds(k,9);
			if (k>=250) return randProbPrimeRounds(k,12); //numbers from HAC table 4.4
			if (k>=200) return randProbPrimeRounds(k,15);
			if (k>=150) return randProbPrimeRounds(k,18);
			if (k>=100) return randProbPrimeRounds(k,27);
			return randProbPrimeRounds(k,40); //number from HAC remark 4.26 (only an estimate)
		}
		
		
		//return a k-bit probable random prime using n rounds of Miller Rabin (after trial division with small primes)
		public static function randProbPrimeRounds(k:int,n:int):BigInt {
			var t_ret:BigInt = new BigInt();
			t_ret.val = randProbPrimeRounds_(k,n);
			if(t_ret.val==null) return null;
			return t_ret;
		}
		private static function randProbPrimeRounds_(k:int,n:int):Array {
			var ans:Array, i:int, divisible:Boolean, B:int; 
			B=30000;  //B is largest prime to use in trial division
			var t_ans:BigInt = int2bigInt(0,k,0);
			if(t_ans==null || t_ans.val==null) return null;
			ans = t_ans.val;
			
			//optimization: try larger and smaller B to find the best limit.
			
			if (primes.length==0)
				primes=findPrimes(30000);  //check for divisibility by primes <=30000
			
			if (rpprb.length!=ans.length)
				rpprb=dup_(ans);
			
			for (;;) { //keep trying random values for ans until one appears to be prime
				//optimization: pick a random number times L=2*3*5*...*p, plus a 
				//   random element of the list of all numbers in [0,L) not divisible by any prime up to p.
				//   This can reduce the amount of random number generation.
				
				randBigInt_(ans,k,false); //ans = a random odd number to check
				ans[0] |= 1; 
				divisible=false;
				
				//check ans for divisibility by small primes up to B
				for (i=0; (i<primes.length) && (primes[i]<=B); i++)
					if (modInt_(ans,primes[i])==0 && !equalsInt_(ans,primes[i])) {
						divisible=true;
						break;
					}      
				
				//optimization: change millerRabin so the base can be bigger than the number being checked, then eliminate the while here.
				
				//do n rounds of Miller Rabin, with random bases less than ans
				for (i=0; i<n && !divisible; i++) {
					randBigInt_(rpprb,k,false);
					while(!greater_(ans,rpprb)) //pick a random rpprb that's < ans
						randBigInt_(rpprb,k,false);
					if (!millerRabin_(ans,rpprb))
						divisible=true;
				}
				
				if(!divisible)
					return ans;
			}  
			return null;
		}
		
		//return a new bigInt equal to (x mod n) for bigInts x and n.
		public static function mod(x:BigInt,n:BigInt):BigInt {
			var ans:BigInt=dup(x);
			mod_(ans.val,n.val);
			return trim(ans,1);
		}
		
		//return (x+n) where x is a bigInt and n is an integer.
		public static function addInt(x:BigInt,n:int):BigInt {
			var ans:BigInt=expand(x,x.val.length+1);
			addInt_(ans.val,n);
			return trim(ans,1);
		}
		
		//return x*y for bigInts x and y. This is faster when y<x.
		public static function mult(x:BigInt,y:BigInt):BigInt {
			var ans:BigInt=expand(x,x.val.length+y.val.length);
			mult_(ans.val,y.val);
			return trim(ans,1);
		}
		
		//return (x**y mod n) where x,y,n are bigInts and ** is exponentiation.  0**0=1. Faster for odd n.
		public static function powMod(x:BigInt,y:BigInt,n:BigInt):BigInt {
			var ans:BigInt=expand(x,n.val.length);
			powMod_(ans.val,trim(y,2).val,trim(n,2).val);  //this should work without the trim, but doesn't
			return trim(ans,1);
		}
		
		//return (x-y) for bigInts x and y.  Negative answers will be 2s complement
		public static function sub(x:BigInt,y:BigInt):BigInt {
			var ans:BigInt=expand(x,(x.val.length>y.val.length ? x.val.length+1 : y.val.length+1)); 
			sub_(ans.val,y.val);
			return trim(ans,1);
		}
		
		//return (x+y) for bigInts x and y.  
		public static function add(x:BigInt,y:BigInt):BigInt {
			var ans:BigInt=expand(x,(x.val.length>y.val.length ? x.val.length+1 : y.val.length+1)); 
			add_(ans.val,y.val);
			return trim(ans,1);
		}
		
		
		//return (x**(-1) mod n) for bigInts x and n.  If no inverse exists, it returns null
		public static function inverseMod(x:BigInt,n:BigInt):BigInt {
			if(x==null || n==null) return null;
			var ans:BigInt=expand(x,n.val.length); 
			var s:Boolean;
			s=inverseMod_(ans.val,n.val);
			return s ? trim(ans,1) : null;
		}
		
		
		//return (x*y mod n) for bigInts x,y,n.  For greater speed, let y<x.
		public static function multMod(x:BigInt,y:BigInt,n:BigInt):BigInt {
			var ans:BigInt=expand(x,n.val.length);
			multMod_(ans.val,y.val,n.val);
			return trim(ans,1);
		}
		
		
		//generate a k-bit true random prime using Maurer's algorithm,
		//and put it into ans.  The bigInt ans must be large enough to hold it.
		private static function randTruePrime_(ans:Array,k:int):void {
			var c:Number,m:int,pm:Number,dd:int,j:int,r:Number,B:Number;
			var divisible:Boolean,z:int,zz:int,recSize:int;
			var recLimit:int, w:int;
			
			if (primes.length==0)
				primes=findPrimes(30000);  //check for divisibility by primes <=30000
			
			if (pows.length==0) {
				pows=new Array(512);
				for (j=0;j<512;j++) {
					pows[j]=Math.pow(2,j/511.-1.);
				}
			}
			
			//c and m should be tuned for a particular machine and value of k, to maximize speed
			c=0.1;  //c=0.1 in HAC
			m=20;   //generate this k-bit number by first recursively generating a number that has between k/2 and k-m bits
			recLimit=20; //stop recursion when k <=recLimit.  Must have recLimit >= 2
			
			if (s_i2.length!=ans.length) {
				s_i2=dup_(ans);
				s_R =dup_(ans);
				s_n1=dup_(ans);
				s_r2=dup_(ans);
				s_d =dup_(ans);
				s_x1=dup_(ans);
				s_x2=dup_(ans);
				s_b =dup_(ans);
				s_n =dup_(ans);
				s_i =dup_(ans);
				s_rm=dup_(ans);
				s_q =dup_(ans);
				s_a =dup_(ans);
				s_aa=dup_(ans);
			}
			
			if (k <= recLimit) {  //generate small random primes by trial division up to its square root
				pm=(1<<((k+2)>>1))-1; //pm is binary number with all ones, just over sqrt(2^k)
				copyInt_(ans,0);
				for (dd=1;dd;) {
					dd=0;
					ans[0]= 1 | (1<<(k-1)) | Math.floor(Math.random()*(1<<k));  //random, k-bit, odd integer, with msb 1
					for (j=1;(j<primes.length) && ((primes[j]&pm)==primes[j]);j++) { //trial division by all primes 3...sqrt(2^k)
						if (0==(ans[0]%primes[j])) {
							dd=1;
							break;
						}
					}
				}
				carry_(ans);
				return;
			}
			
			B=c*k*k;    //try small primes up to B (or all the primes[] array if the largest is less than B).
			if (k>2*m)  //generate this k-bit number by first recursively generating a number that has between k/2 and k-m bits
				for (r=1; k-k*r<=m; )
					r=pows[Math.floor(Math.random()*512)];   //r=Math.pow(2,Math.random()-1);
			else
				r=.5;
			
			//simulation suggests the more complex algorithm using r=.333 is only slightly faster.
			
			recSize=Math.floor(r*k)+1;
			
			randTruePrime_(s_q,recSize);
			copyInt_(s_i2,0);
			s_i2[Math.floor((k-2)/bpe)] |= (1<<((k-2)%bpe));   //s_i2=2^(k-2)
			divide_(s_i2,s_q,s_i,s_rm);                        //s_i=floor((2^(k-1))/(2q))
			
			z=bitSize_(s_i);
			
			for (;;) {
				for (;;) {  //generate z-bit numbers until one falls in the range [0,s_i-1]
					randBigInt_(s_R,z,false);
					if (greater_(s_i,s_R))
						break;
				}                //now s_R is in the range [0,s_i-1]
				addInt_(s_R,1);  //now s_R is in the range [1,s_i]
				add_(s_R,s_i);   //now s_R is in the range [s_i+1,2*s_i]
				
				copy_(s_n,s_q);
				mult_(s_n,s_R); 
				multInt_(s_n,2);
				addInt_(s_n,1);    //s_n=2*s_R*s_q+1
				
				copy_(s_r2,s_R);
				multInt_(s_r2,2);  //s_r2=2*s_R
				
				//check s_n for divisibility by small primes up to B
				for (divisible=false,j=0; (j<primes.length) && (primes[j]<B); j++)
					if (modInt_(s_n,primes[j])==0 && !equalsInt_(s_n,primes[j])) {
						divisible=true;
						break;
					}      
				
				if (!divisible)    //if it passes small primes check, then try a single Miller-Rabin base 2
					if (!millerRabinInt_(s_n,2)) //this line represents 75% of the total runtime for randTruePrime_ 
						divisible=true;
				
				if (!divisible) {  //if it passes that test, continue checking s_n
					addInt_(s_n,-3);
					for (j=s_n.length-1;(s_n[j]==0) && (j>0); j--){};  //strip leading zeros
					for (zz=0,w=s_n[j]; w; (w>>=1),zz++){};
					zz+=bpe*j;                             //zz=number of bits in s_n, ignoring leading zeros
					for (;;) {  //generate z-bit numbers until one falls in the range [0,s_n-1]
						randBigInt_(s_a,zz,false);
						if (greater_(s_n,s_a))
							break;
					}                //now s_a is in the range [0,s_n-1]
					addInt_(s_n,3);  //now s_a is in the range [0,s_n-4]
					addInt_(s_a,2);  //now s_a is in the range [2,s_n-2]
					copy_(s_b,s_a);
					copy_(s_n1,s_n);
					addInt_(s_n1,-1);
					powMod_(s_b,s_n1,s_n);   //s_b=s_a^(s_n-1) modulo s_n
					addInt_(s_b,-1);
					if (isZero_(s_b)) {
						copy_(s_b,s_a);
						powMod_(s_b,s_r2,s_n);
						addInt_(s_b,-1);
						copy_(s_aa,s_n);
						copy_(s_d,s_b);
						GCD_(s_d,s_n);  //if s_b and s_n are relatively prime, then s_n is a prime
						if (equalsInt_(s_d,1)) {
							copy_(ans,s_aa);
							return;     //if we've made it this far, then s_n is absolutely guaranteed to be prime
						}
					}
				}
			}
		}
		
		
		
		//Return an n-bit random BigInt (n>=1).  If s=1, then the most significant of those n bits is set to 1.
		public static function randBigInt(n:int,s:Boolean):BigInt {
			var a:int,b:BigInt;
			a=Math.floor((n-1)/bpe)+2; //# array elements to hold the BigInt with a leading 0 element
			b=int2bigInt(0,0,a);
			randBigInt_(b.val,n,s);
			return b;
		}
		
		//Set b to an n-bit random BigInt.  If s=1, then the most significant of those n bits is set to 1.
		//Array b must be big enough to hold the result. Must have n>=1
		private static function randBigInt_(b:Array,n:int,s:Boolean):void {
			var i:int,a:int;
			for (i=0;i<b.length;i++)
				b[i]=0;
			a=Math.floor((n-1)/bpe)+1; //# array elements to hold the BigInt
			for (i=0;i<a;i++) {
				b[i]=Math.floor(Math.random()*(1<<(bpe-1)));
			}
			b[a-1] &= (2<<((n-1)%bpe))-1;
			if (s)
				b[a-1] |= (1<<((n-1)%bpe));
		}
		
		
		
		//Return the greatest common divisor of bigInts x and y (each with same number of elements).
		public static function GCD(x:BigInt,y:BigInt):BigInt {
			var xc:BigInt,yc:BigInt;
			xc=dup(x);
			yc=dup(y);
			GCD_(xc.val,yc.val);
			return xc;
		}
		
		//set x to the greatest common divisor of bigInts x and y (each with same number of elements).
		//y is destroyed.
		private static function GCD_(x:Array,y:Array):void {
			var i:int,xp:int,yp:int,A:int,B:int,C:int,D:int,q:int,sing:Boolean;
			var qp:int;
			var t_i:int;
			if (T.length!=x.length)
				T=dup_(x);
			
			sing=true;
			while (sing) { //while y has nonzero elements other than y[0]
				sing=false;
				for (i=1;i<y.length;i++) //check if y has nonzero elements other than 0
					if (y[i]) {
						sing=true;
						break;
					}
				if (!sing) break; //quit when y all zero elements except possibly y[0]
				
				for (i=x.length;!x[i] && i>=0;i--){};  //find most significant element of x
				xp=x[i];
				yp=y[i];
				A=1; B=0; C=0; D=1;
				while ((yp+C) && (yp+D)) {
					q =Math.floor((xp+A)/(yp+C));
					qp=Math.floor((xp+B)/(yp+D));
					if (q!=qp)
						break;
					t_i= A-q*C;   A=C;   C=t_i;    //  do (A,B,xp, C,D,yp) = (C,D,yp, A,B,xp) - q*(0,0,0, C,D,yp)      
					t_i= B-q*D;   B=D;   D=t_i;
					t_i=xp-q*yp; xp=yp; yp=t_i;
				}
				if (B) {
					copy_(T,x);
					linComb_(x,y,A,B); //x=A*x+B*y
					linComb_(y,T,D,C); //y=D*y+C*T
				} else {
					mod_(x,y);
					copy_(T,x);
					copy_(x,y);
					copy_(y,T);
				} 
			}
			if (y[0]==0)
				return;
			t_i=modInt_(x,y[0]);
			copyInt_(x,y[0]);
			y[0]=t_i;
			while (y[0]) {
				x[0]%=y[0];
				t=x[0]; x[0]=y[0]; y[0]=t_i;
			}
		}
		
		
		
		//do x=x**(-1) mod n, for bigInts x and n.
		//If no inverse exists, it sets x to zero and returns false, else it returns true.
		//The x array must be at least as large as the n array.
		private static function inverseMod_(x:Array,n:Array):Boolean {
			var k:int=1+2*Math.max(x.length,n.length);
			
			if(!(x[0]&1)  && !(n[0]&1)) {  //if both inputs are even, then inverse doesn't exist
				copyInt_(x,0);
				return false;
			}
			
			if (eg_u.length!=k) {
				eg_u=new Array(k);
				eg_v=new Array(k);
				eg_A=new Array(k);
				eg_B=new Array(k);
				eg_C=new Array(k);
				eg_D=new Array(k);
			}
			
			copy_(eg_u,x);
			copy_(eg_v,n);
			copyInt_(eg_A,1);
			copyInt_(eg_B,0);
			copyInt_(eg_C,0);
			copyInt_(eg_D,1);
			for (;;) {
				while(!(eg_u[0]&1)) {  //while eg_u is even
					halve_(eg_u);
					if (!(eg_A[0]&1) && !(eg_B[0]&1)) { //if eg_A==eg_B==0 mod 2
						halve_(eg_A);
						halve_(eg_B);      
					} else {
						add_(eg_A,n);  halve_(eg_A);
						sub_(eg_B,x);  halve_(eg_B);
					}
				}
				
				while (!(eg_v[0]&1)) {  //while eg_v is even
					halve_(eg_v);
					if (!(eg_C[0]&1) && !(eg_D[0]&1)) { //if eg_C==eg_D==0 mod 2
						halve_(eg_C);
						halve_(eg_D);      
					} else {
						add_(eg_C,n);  halve_(eg_C);
						sub_(eg_D,x);  halve_(eg_D);
					}
				}
				
				if (!greater_(eg_v,eg_u)) { //eg_v <= eg_u
					sub_(eg_u,eg_v);
					sub_(eg_A,eg_C);
					sub_(eg_B,eg_D);
				} else {                   //eg_v > eg_u
					sub_(eg_v,eg_u);
					sub_(eg_C,eg_A);
					sub_(eg_D,eg_B);
				}
				
				if (equalsInt_(eg_u,0)) {
					if (negative_(eg_C)) //make sure answer is nonnegative
						add_(eg_C,n);
					copy_(x,eg_C);
					
					if (!equalsInt_(eg_v,1)) { //if GCD_(x,n)!=1, then there is no inverse
						copyInt_(x,0);
						return false;
					}
					return true;
				}
			}
			return false;
		}
		
		
		
		//return x**(-1) mod n, for integers x and n.  Return 0 if there is no inverse
		public static function inverseModInt(x:int,n:int):int {
			var a:int=1,b:int=0;
			for (;;) {
				if (x==1) return a;
				if (x==0) return 0;
				b-=a*Math.floor(n/x);
				n%=x;
				
				if (n==1) return b; //to avoid negatives, change this b to n-b, and each -= to +=
				if (n==0) return 0;
				a-=b*Math.floor(x/n);
				x%=n;
			}
			return 0;
		}
		
		/*
		//this deprecated function is for backward compatibility only. 
		private static function inverseModInt_(x,n) {
		return inverseModInt(x,n);
		}
		*/
		
		
		//Given positive bigInts x and y, change the bigints v, a, and b to positive bigInts such that:
		//     v = GCD_(x,y) = a*x-b*y
		//The bigInts v, a, b, must have exactly as many elements as the larger of x and y.
		public static function eGCD(x:BigInt,y:BigInt,v:BigInt,a:BigInt,b:BigInt):Boolean {
			if(x==null || y==null || v==null || a==null || b==null ) return false;
			if(x.val.length!=y.val.length) return false;
			if(x.val.length!=v.val.length) return false;
			if(x.val.length!=a.val.length) return false;
			if(x.val.length!=b.val.length) return false;
			
			eGCD_(x.val,y.val,v.val,a.val,b.val);
			return true;
		}
		private static function eGCD_(x:Array,y:Array,v:Array,a:Array,b:Array):void {
			var g:int=0;
			var k:int=Math.max(x.length,y.length);
			if (eg_u.length!=k) {
				eg_u=new Array(k);
				eg_A=new Array(k);
				eg_B=new Array(k);
				eg_C=new Array(k);
				eg_D=new Array(k);
			}
			while(!(x[0]&1)  && !(y[0]&1)) {  //while x and y both even
				halve_(x);
				halve_(y);
				g++;
			}
			copy_(eg_u,x);
			copy_(v,y);
			copyInt_(eg_A,1);
			copyInt_(eg_B,0);
			copyInt_(eg_C,0);
			copyInt_(eg_D,1);
			for (;;) {
				while(!(eg_u[0]&1)) {  //while u is even
					halve_(eg_u);
					if (!(eg_A[0]&1) && !(eg_B[0]&1)) { //if A==B==0 mod 2
						halve_(eg_A);
						halve_(eg_B);      
					} else {
						add_(eg_A,y);  halve_(eg_A);
						sub_(eg_B,x);  halve_(eg_B);
					}
				}
				
				while (!(v[0]&1)) {  //while v is even
					halve_(v);
					if (!(eg_C[0]&1) && !(eg_D[0]&1)) { //if C==D==0 mod 2
						halve_(eg_C);
						halve_(eg_D);      
					} else {
						add_(eg_C,y);  halve_(eg_C);
						sub_(eg_D,x);  halve_(eg_D);
					}
				}
				
				if (!greater_(v,eg_u)) { //v<=u
					sub_(eg_u,v);
					sub_(eg_A,eg_C);
					sub_(eg_B,eg_D);
				} else {                //v>u
					sub_(v,eg_u);
					sub_(eg_C,eg_A);
					sub_(eg_D,eg_B);
				}
				if (equalsInt_(eg_u,0)) {
					if (negative_(eg_C)) {   //make sure a (C)is nonnegative
						add_(eg_C,y);
						sub_(eg_D,x);
					}
					multInt_(eg_D,-1);  ///make sure b (D) is nonnegative
					copy_(a,eg_C);
					copy_(b,eg_D);
					leftShift_(v,g);
					return;
				}
			}
		}
		
		
		//is bigInt x negative?
		public static function negative(x:BigInt):Boolean {
			return negative_(x.val);
		}
		public static function negative_(x:Array):Boolean {
			return (((x[x.length-1]>>(bpe-1))&1)!=0);
		}	
		
		//is (x << (shift*bpe)) > y?
		//x and y are nonnegative bigInts
		//shift is a nonnegative integer
		public static function greaterShift(x:BigInt,y:BigInt,shift:int):Boolean {
			return greaterShift_(x.val, y.val, shift);
		}
		public static function greaterShift_(x:Array,y:Array,shift:int):Boolean {
			var i:int, kx:int=x.length, ky:int=y.length;
			var k:int=((kx+shift)<ky) ? (kx+shift) : ky;
			for (i=ky-1-shift; i<kx && i>=0; i++) 
				if (x[i]>0)
					return true; //if there are nonzeros in x to the left of the first column of y, then x is bigger
			for (i=kx-1+shift; i<ky; i++)
				if (y[i]>0)
					return false; //if there are nonzeros in y to the left of the first column of x, then x is not bigger
			for (i=k-1; i>=shift; i--)
				if      (x[i-shift]>y[i]) return true;
				else if (x[i-shift]<y[i]) return false;
			return false;
		}
		
		//is x > y? (x and y both nonnegative)
		public static function greater(x:BigInt,y:BigInt):Boolean {
			return greater_(x.val, y.val);
		}
		public static function greater_(x:Array,y:Array):Boolean {
			var i:int;
			var k:int=(x.length<y.length) ? x.length : y.length;
			
			for (i=x.length;i<y.length;i++)
				if (y[i])
					return false;  //y has more digits
			
			for (i=y.length;i<x.length;i++)
				if (x[i])
					return true;  //x has more digits
			
			for (i=k-1;i>=0;i--)
				if (x[i]>y[i])
					return true;
				else if (x[i]<y[i])
					return false;
			return false;
		}
		
		//divide x by y giving quotient q and remainder r.  (q=floor(x/y),  r=x mod y).  All 4 are bigints.
		//x must have at least one leading zero element.
		//y must be nonzero.
		//q and r must be arrays that are exactly the same length as x. (Or q can have more).
		//Must have x.length >= y.length >= 2.
		private static function divide_(x:Array,y:Array,q:Array,r:Array):void {
			var kx:int, ky:int;
			var i:int,j:int,y1:int,y2:int,c:int,a:int,b:int;
			copy_(r,x);
			for (ky=y.length;y[ky-1]==0;ky--){}; //ky is number of elements in y, not including leading zeros
			
			//normalize: ensure the most significant element of y has its highest bit set  
			b=y[ky-1];
			for (a=0; b; a++)
				b>>=1;  
			a=bpe-a;  //a is how many bits to shift so that the high order bit of y is leftmost in its array element
			leftShift_(y,a);  //multiply both by 1<<a now, then divide both by that at the end
			leftShift_(r,a);
			
			//Rob Visser discovered a bug: the following line was originally just before the normalization.
			for (kx=r.length;r[kx-1]==0 && kx>ky;kx--){}; //kx is number of elements in normalized x, not including leading zeros
			
			copyInt_(q,0);                      // q=0
			while (!greaterShift_(y,r,kx-ky)) {  // while (leftShift_(y,kx-ky) <= r) {
				subShift_(r,y,kx-ky);             //   r=r-leftShift_(y,kx-ky)
				q[kx-ky]++;                       //   q[kx-ky]++;
			}                                   // }
			
			for (i=kx-1; i>=ky; i--) {
				if (r[i]==y[ky-1])
					q[i-ky]=mask;
				else
					q[i-ky]=Math.floor((r[i]*radix+r[i-1])/y[ky-1]);	
				
				//The following for(;;) loop is equivalent to the commented while loop, 
				//except that the uncommented version avoids overflow.
				//The commented loop comes from HAC, which assumes r[-1]==y[-1]==0
				//  while (q[i-ky]*(y[ky-1]*radix+y[ky-2]) > r[i]*radix*radix+r[i-1]*radix+r[i-2])
				//    q[i-ky]--;    
				for (;;) {
					y2=(ky>1 ? y[ky-2] : 0)*q[i-ky];
					c=y2>>bpe;
					y2=y2 & mask;
					y1=c+q[i-ky]*y[ky-1];
					c=y1>>bpe;
					y1=y1 & mask;
					
					if (c==r[i] ? y1==r[i-1] ? y2>(i>1 ? r[i-2] : 0) : y1>r[i-1] : c>r[i]) 
						q[i-ky]--;
					else
						break;
				}
				
				linCombShift_(r,y,-q[i-ky],i-ky);    //r=r-q[i-ky]*leftShift_(y,i-ky)
				if (negative_(r)) {
					addShift_(r,y,i-ky);         //r=r+leftShift_(y,i-ky)
					q[i-ky]--;
				}
			}
			
			rightShift_(y,a);  //undo the normalization step
			rightShift_(r,a);  //undo the normalization step
		}
		
		//do carries and borrows so each element of the bigInt x fits in bpe bits.
		private static function carry_(x:Array):void {
			var i:int,k:int,c:int,b:int;
			k=x.length;
			c=0;
			for (i=0;i<k;i++) {
				c+=x[i];
				b=0;
				if (c<0) {
					b=-(c>>bpe);
					c+=b*radix;
				}
				x[i]=c & mask;
				c=(c>>bpe)-b;
			}
		}
		
		//return x mod n for bigInt x and integer n.
		public static function modInt(x:BigInt,n:int):int {
			return modInt_(x.val,n);
		}
		public static function modInt_(x:Array,n:int):int {
			var i:int,c:int=0;
			for (i=x.length-1; i>=0; i--)
				c=(c*radix+x[i])%n;
			return c;
		}	
		//convert the integer t into a bigInt with at least the given number of bits.
		//the returned array stores the bigInt in bpe-bit chunks, little endian (buff[0] is least significant word)
		//Pad the array with leading zeros so that it has at least minSize elements.
		//There will always be at least one leading 0 element.
		public static function int2bigInt(t:int,bits:int,minSize:int):BigInt {   
			var i:int,k:int;
			k=Math.ceil(bits/bpe)+1;
			k=minSize>k ? minSize : k;
			var buff:BigInt=new BigInt();
			buff.val = new Array(k);
			copyInt_(buff.val,t);
			return buff;
		}
		
		//return the bigInt given a string representation in a given base.  
		//Pad the array with leading zeros so that it has at least minSize elements.
		//If base=-1, then it reads in a space-separated list of array elements in decimal.
		//The array will always have at least one leading zero, unless base=-1.
		public static function str2bigInt(s:String,base:int,minSize:int):BigInt {
			var d:int, i:int, j:int, x:Array, y:Array, kk:int;
			var k:int=s.length;
			if (base==-1) { //comma-separated list of array elements in decimal
				x=new Array(0);
				for (;;) {
					y=new Array(x.length+1);
					for (i=0;i<x.length;i++)
						y[i+1]=x[i];
					y[0]=parseInt(s,10);
					x=y;
					d=s.indexOf(',',0);
					if (d<1) 
						break;
					s=s.substring(d+1);
					if (s.length==0)
						break;
				}
				if (x.length<minSize) {
					y=new Array(minSize);
					copy_(y,x);
					return new BigInt(y);
				}
				return new BigInt(x);
			}
			
			var xtemp:BigInt=int2bigInt(0,base*k,0);
			x = xtemp.val;
			for (i=0;i<k;i++) {
				d=digitsStr.indexOf(s.substring(i,i+1),0);
				if (base<=36 && d>=36)  //convert lowercase to uppercase if base<=36
					d-=26;
				if (d>=base || d<0) {   //stop at first illegal character
					break;
				}
				multInt_(x,base);
				addInt_(x,d);
			}
			
			for (k=x.length;k>0 && !x[k-1];k--){}; //strip off leading zeros
			k=minSize>k+1 ? minSize : k+1;
			y=new Array(k);
			kk=k<x.length ? k : x.length;
			for (i=0;i<kk;i++)
				y[i]=x[i];
			for (;i<k;i++)
				y[i]=0;
			return new BigInt(y);
		}
		
		//is bigint x equal to integer y?
		//y must have less than bpe bits
		public static function equalsInt(x:BigInt,y:int):Boolean {
			return equalsInt_(x.val, y);
		}
		public static function equalsInt_(x:Array,y:int):Boolean {
			var i:int;
			if (x[0]!=y)
				return false;
			for (i=1;i<x.length;i++)
				if (x[i])
					return false;
			return true;
		}
		
		//are bigints x and y equal?
		//this works even if x and y are different lengths and have arbitrarily many leading zeros
		public static function equals(x:BigInt,y:BigInt):Boolean {
			if(x==null && y!=null) return false;
			if(x!=null && y==null) return false;
			if(x==null && y==null) return true;
			
			return equals_(x.val, y.val);
		}
		private static function equals_(x:Array,y:Array):Boolean {
			var i:int;
			var k:int=x.length<y.length ? x.length : y.length;
			for (i=0;i<k;i++)
				if (x[i]!=y[i])
					return false;
			if (x.length>y.length) {
				for (;i<x.length;i++)
					if (x[i])
						return false;
			} else {
				for (;i<y.length;i++)
					if (y[i])
						return false;
			}
			return true;
		}
		
		//is the bigInt x equal to zero?
		public static function isZero(x:BigInt):Boolean {
			return isZero_(x.val);
		}
		
		//is the bigInt x equal to zero?
		private static function isZero_(x:Array):Boolean {
			var i:int;
			for (i=0;i<x.length;i++)
				if (x[i])
					return false;
			return true;
		}
		
		//convert a bigInt into a string in a given base, from base 2 up to base 95.
		//Base -1 prints the contents of the array representing the number.
		public static function bigInt2str(x:BigInt,base:int):String {
			var i:int,t:int,s:String="";
			
			if (s6.length!=x.val.length) 
				s6=dup_(x.val);
			else
				copy_(s6,x.val);
			
			if (base==-1) { //return the list of array contents
				for (i=x.val.length-1;i>0;i--)
					s+=x.val[i]+',';
				s+=x.val[0];
			}
			else { //return it in the given base
				while (!isZero_(s6)) {
					t=divInt_(s6,base);  //t=s6 % base; s6=floor(s6/base);
					s=digitsStr.substring(t,t+1)+s;
				}
			}
			if (s.length==0)
				s="0";
			return s;
		}
		
		//returns a duplicate of bigInt x
		public static function dup(x:BigInt):BigInt {
			var i:int;
			var buff:BigInt=new BigInt();
			buff.val = new Array(x.val.length);
			copy_(buff.val,x.val);
			return buff;
		}
		//returns a duplicate of bigInt x
		public static function dup_(x:Array):Array {
			var i:int;
			var buff:Array=new Array(x.length);
			copy_(buff,x);
			return buff;
		}
		
		//do x=y on bigInts x and y.  x must be an array at least as big as y (not counting the leading zeros in y).
		private static function copy_(x:Array,y:Array):void {
			var i:int;
			var k:int=x.length<y.length ? x.length : y.length;
			for (i=0;i<k;i++)
				x[i]=y[i];
			for (i=k;i<x.length;i++)
				x[i]=0;
		}
		
		//do x=y on bigInt x and integer y.  
		private static function copyInt_(x:Array,n:int):void {
			var i:int,c:int;
			for (c=n,i=0;i<x.length;i++) {
				x[i]=c & mask;
				c>>=bpe;
			}
		}
		
		//do x=x+n where x is a bigInt and n is an integer.
		//x must be large enough to hold the result.
		private static function addInt_(x:Array,n:int):void {
			var i:int,k:int,c:int,b:int;
			x[0]+=n;
			k=x.length;
			c=0;
			for (i=0;i<k;i++) {
				c+=x[i];
				b=0;
				if (c<0) {
					b=-(c>>bpe);
					c+=b*radix;
				}
				x[i]=c & mask;
				c=(c>>bpe)-b;
				if (!c) return; //stop carrying as soon as the carry is zero
			}
		}
		
		//right shift bigInt x by n bits.  0 <= n < bpe.
		private static function rightShift_(x:Array,n:int):void {
			var i:int;
			var k:int=Math.floor(n/bpe);
			if (k) {
				for (i=0;i<x.length-k;i++) //right shift x by k elements
					x[i]=x[i+k];
				for (;i<x.length;i++)
					x[i]=0;
				n%=bpe;
			}
			for (i=0;i<x.length-1;i++) {
				x[i]=mask & ((x[i+1]<<(bpe-n)) | (x[i]>>n));
			}
			x[i]>>=n;
		}
		
		//do x=floor(|x|/2)*sgn(x) for bigInt x in 2's complement
		private static function halve_(x:Array):void {
			var i:int;
			for (i=0;i<x.length-1;i++) {
				x[i]=mask & ((x[i+1]<<(bpe-1)) | (x[i]>>1));
			}
			x[i]=(x[i]>>1) | (x[i] & (radix>>1));  //most significant bit stays the same
		}
		
		//left shift bigInt x by n bits.
		private static function leftShift_(x:Array,n:int):void {
			var i:int;
			var k:int=Math.floor(n/bpe);
			if (k!=0) {
				for (i=x.length; i>=k; i--) //left shift x by k elements
					x[i]=x[i-k];
				for (;i>=0;i--)
					x[i]=0;  
				n%=bpe;
			}
			if (!n)
				return;
			for (i=x.length-1;i>0;i--) {
				x[i]=mask & ((x[i]<<n) | (x[i-1]>>(bpe-n)));
			}
			x[i]=mask & (x[i]<<n);
		}
		
		//do x=x*n where x is a bigInt and n is an integer.
		//x must be large enough to hold the result.
		private static function multInt_(x:Array,n:int):void {
			var i:int,k:int,c:int,b:int;
			if (!n)
				return;
			k=x.length;
			c=0;
			for (i=0;i<k;i++) {
				c+=x[i]*n;
				b=0;
				if (c<0) {
					b=-(c>>bpe);
					c+=b*radix;
				}
				x[i]=c & mask;
				c=(c>>bpe)-b;
			}
		}
		
		//do x=floor(x/n) for bigInt x and integer n, and return the remainder
		private static function divInt_(x:Array,n:int):int {
			var i:int,r:int=0,s:int;
			for (i=x.length-1;i>=0;i--) {
				s=r*radix+x[i];
				x[i]=Math.floor(s/n);
				r=s%n;
			}
			return r;
		}
		
		
		//do the linear combination x=a*x+b*y for bigInts x and y, and integers a and b.
		//x must be large enough to hold the answer.
		private static function linComb_(x:Array,y:Array,a:int,b:int):void {
			var i:int,c:int,k:int,kk:int;
			k=x.length<y.length ? x.length : y.length;
			kk=x.length;
			for (c=0,i=0;i<k;i++) {
				c+=a*x[i]+b*y[i];
				x[i]=c & mask;
				c>>=bpe;
			}
			for (i=k;i<kk;i++) {
				c+=a*x[i];
				x[i]=c & mask;
				c>>=bpe;
			}
		}
		
		
		
		//do the linear combination x=a*x+b*(y<<(ys*bpe)) for bigInts x and y, and integers a, b and ys.
		//x must be large enough to hold the answer.
		private static function linCombShift_(x:Array,y:Array,b:int,ys:int):void {
			var i:int,c:int,k:int,kk:int;
			k=x.length<ys+y.length ? x.length : ys+y.length;
			kk=x.length;
			for (c=0,i=ys;i<k;i++) {
				c+=x[i]+b*y[i-ys];
				x[i]=c & mask;
				c>>=bpe;
			}
			for (i=k;c && i<kk;i++) {
				c+=x[i];
				x[i]=c & mask;
				c>>=bpe;
			}
		}		
		
		//do x=x+(y<<(ys*bpe)) for bigInts x and y, and integers a,b and ys.
		//x must be large enough to hold the answer.
		private static function addShift_(x:Array,y:Array,ys:int):void {
			var i:int,c:int,k:int,kk:int;
			k=x.length<ys+y.length ? x.length : ys+y.length;
			kk=x.length;
			for (c=0,i=ys;i<k;i++) {
				c+=x[i]+y[i-ys];
				x[i]=c & mask;
				c>>=bpe;
			}
			for (i=k;c && i<kk;i++) {
				c+=x[i];
				x[i]=c & mask;
				c>>=bpe;
			}
		}		
		
		//do x=x-(y<<(ys*bpe)) for bigInts x and y, and integers a,b and ys.
		//x must be large enough to hold the answer.
		private static function subShift_(x:Array,y:Array,ys:int):void {
			var i:int,c:int,k:int,kk:int;
			k=x.length<ys+y.length ? x.length : ys+y.length;
			kk=x.length;
			for (c=0,i=ys;i<k;i++) {
				c+=x[i]-y[i-ys];
				x[i]=c & mask;
				c>>=bpe;
			}
			for (i=k;c && i<kk;i++) {
				c+=x[i];
				x[i]=c & mask;
				c>>=bpe;
			}
		}
		
		//do x=x-y for bigInts x and y.
		//x must be large enough to hold the answer.
		//negative answers will be 2s complement
		private static function sub_(x:Array,y:Array):void {
			var i:int,c:int,k:int,kk:int;
			k=x.length<y.length ? x.length : y.length;
			for (c=0,i=0;i<k;i++) {
				c+=x[i]-y[i];
				x[i]=c & mask;
				c>>=bpe;
			}
			for (i=k;c && i<x.length;i++) {
				c+=x[i];
				x[i]=c & mask;
				c>>=bpe;
			}
		}
		
		
		
		//do x=x+y for bigInts x and y.
		//x must be large enough to hold the answer.
		private static function add_(x:Array,y:Array):void {
			var i:int,c:int,k:int,kk:int;
			k=x.length<y.length ? x.length : y.length;
			for (c=0,i=0;i<k;i++) {
				c+=x[i]+y[i];
				x[i]=c & mask;
				c>>=bpe;
			}
			for (i=k;c && i<x.length;i++) {
				c+=x[i];
				x[i]=c & mask;
				c>>=bpe;
			}
		}
		
		
		//do x=x*y for bigInts x and y.  This is faster when y<x.
		private static function mult_(x:Array,y:Array):void {
			var i:int;
			if (ss.length!=2*x.length)
				ss=new Array(2*x.length);
			copyInt_(ss,0);
			for (i=0;i<y.length;i++)
				if (y[i])
					linCombShift_(ss,x,y[i],i);   //ss=1*ss+y[i]*(x<<(i*bpe))
			copy_(x,ss);
		}
		
		//do x=x mod n for bigInts x and n.
		private static function mod_(x:Array,n:Array):void {
			if (s4.length!=x.length)
				s4=dup_(x);
			else
				copy_(s4,x);
			if (s5.length!=x.length)
				s5=dup_(x);  
			divide_(s4,n,s5,x);  //x = remainder of s4 / n
		}
		
		
		//do x=x*y mod n for bigInts x,y,n.
		//for greater speed, let y<x.
		private static function multMod_(x:Array,y:Array,n:Array):void {
			var i:int;
			if (s0.length!=2*x.length)
				s0=new Array(2*x.length);
			copyInt_(s0,0);
			for (i=0;i<y.length;i++)
				if (y[i])
					linCombShift_(s0,x,y[i],i);   //s0=1*s0+y[i]*(x<<(i*bpe))
			mod_(s0,n);
			copy_(x,s0);
		}
		
		
		
		//do x=x*x mod n for bigInts x,n.
		private static function squareMod_(x:Array,n:Array):void {
			var i:int,j:int,d:int,c:int,kx:int,kn:int,k:int;
			for (kx=x.length; kx>0 && !x[kx-1]; kx--){};  //ignore leading zeros in x
			k=kx>n.length ? 2*kx : 2*n.length; //k=# elements in the product, which is twice the elements in the larger of x and n
			if (s0.length!=k) 
				s0=new Array(k);
			copyInt_(s0,0);
			for (i=0;i<kx;i++) {
				c=s0[2*i]+x[i]*x[i];
				s0[2*i]=c & mask;
				c>>=bpe;
				for (j=i+1;j<kx;j++) {
					c=s0[i+j]+2*x[i]*x[j]+c;
					s0[i+j]=(c & mask);
					c>>=bpe;
				}
				s0[i+kx]=c;
			}
			mod_(s0,n);
			copy_(x,s0);
		}
		
		
		//return x with exactly k leading zero elements
		public static function trim(x:BigInt,k:int):BigInt {
			var i:int,y:BigInt;
			for (i=x.val.length; i>0 && (x.val[i-1]==0); i--){};
			y=new BigInt();
			y.val=new Array(i+k);
			copy_(y.val,x.val);
			return y;
		}
		
		//do x=x**y mod n, where x,y,n are bigInts and ** is exponentiation.  0**0=1.
		//this is faster when n is odd.  x usually needs to have as many elements as n.
		private static function powMod_(x:Array,y:Array,n:Array):void {
			var k1:int,k2:int,kn:int,np:int;
			if(s7.length!=n.length)
				s7=dup_(n);
			
			//for even modulus, use a simple square-and-multiply algorithm,
			//rather than using the more complex Montgomery algorithm.
			if ((n[0]&1)==0) {
				copy_(s7,x);
				copyInt_(x,1);
				while(!equalsInt_(y,0)) {
					if (y[0]&1)
						multMod_(x,s7,n);
					divInt_(y,2);
					squareMod_(s7,n); 
				}
				return;
			}
			
			//calculate np from n for the Montgomery multiplications
			copyInt_(s7,0);
			for (kn=n.length;kn>0 && !n[kn-1];kn--){};
			np=radix-inverseModInt(modInt_(n,radix),radix);
			s7[kn]=1;
			multMod_(x ,s7,n);   // x = x * 2**(kn*bp) mod n
			
			if (s3.length!=x.length)
				s3=dup_(x);
			else
				copy_(s3,x);
			
			//NOTE: The following line was modified, maybe correctly...
			for (k1=y.length-1;k1>0 && (y[k1])==0; k1--){};  //k1=first nonzero element of y
			if (y[k1]==0) {  //anything to the 0th power is 1
				copyInt_(x,1);
				return;
			}
			for (k2=1<<(bpe-1);k2 && !(y[k1] & k2); k2>>=1){};  //k2=position of first 1 bit in y[k1]
			for (;;) {
				if (!(k2>>=1)) {  //look at next bit of y
					k1--;
					if (k1<0) {
						mont_(x,one.val,n,np);
						return;
					}
					k2=1<<(bpe-1);
				}    
				mont_(x,x,n,np);
				
				if (k2 & y[k1]) //if next bit is a 1
					mont_(x,s3,n,np);
			}
		}
		
		
		//do x=x*y*Ri mod n for bigInts x,y,n, 
		//  where Ri = 2**(-kn*bpe) mod n, and kn is the 
		//  number of elements in the n array, not 
		//  counting leading zeros.  
		//x array must have at least as many elemnts as the n array
		//It's OK if x and y are the same variable.
		//must have:
		//  x,y < n
		//  n is odd
		//  np = -(n^(-1)) mod radix
		private static function mont_(x:Array,y:Array,n:Array,np:int):void {
			var i:int,j:int,c:int,ui:int,t:int,ks:int;
			var kn:int=n.length;
			var ky:int=y.length;
			
			if (sa.length!=kn)
				sa=new Array(kn);
			
			copyInt_(sa,0);
			
			for (;kn>0 && n[kn-1]==0;kn--){}; //ignore leading zeros of n
			for (;ky>0 && y[ky-1]==0;ky--){}; //ignore leading zeros of y
			ks=sa.length-1; //sa will never have more than this many nonzero elements.  
			
			//the following loop consumes 95% of the runtime for randTruePrime_() and powMod_() for large numbers
			for (i=0; i<kn; i++) {
				t=sa[0]+x[i]*y[0];
				ui=((t & mask) * np) & mask;  //the inner "& mask" was needed on Safari (but not MSIE) at one time
				c=(t+ui*n[0]) >> bpe;
				t=x[i];
				
				//do sa=(sa+x[i]*y+ui*n)/b   where b=2**bpe.  Loop is unrolled 5-fold for speed
				j=1;
				for (;j<ky-4;) { c+=sa[j]+ui*n[j]+t*y[j];   sa[j-1]=c & mask;   c>>=bpe;   j++;
					c+=sa[j]+ui*n[j]+t*y[j];   sa[j-1]=c & mask;   c>>=bpe;   j++;
					c+=sa[j]+ui*n[j]+t*y[j];   sa[j-1]=c & mask;   c>>=bpe;   j++;
					c+=sa[j]+ui*n[j]+t*y[j];   sa[j-1]=c & mask;   c>>=bpe;   j++;
					c+=sa[j]+ui*n[j]+t*y[j];   sa[j-1]=c & mask;   c>>=bpe;   j++; }    
				for (;j<ky;)   { c+=sa[j]+ui*n[j]+t*y[j];   sa[j-1]=c & mask;   c>>=bpe;   j++; }
				for (;j<kn-4;) { c+=sa[j]+ui*n[j];          sa[j-1]=c & mask;   c>>=bpe;   j++;
					c+=sa[j]+ui*n[j];          sa[j-1]=c & mask;   c>>=bpe;   j++;
					c+=sa[j]+ui*n[j];          sa[j-1]=c & mask;   c>>=bpe;   j++;
					c+=sa[j]+ui*n[j];          sa[j-1]=c & mask;   c>>=bpe;   j++;
					c+=sa[j]+ui*n[j];          sa[j-1]=c & mask;   c>>=bpe;   j++; }  
				for (;j<kn;)   { c+=sa[j]+ui*n[j];          sa[j-1]=c & mask;   c>>=bpe;   j++; }   
				for (;j<ks;)   { c+=sa[j];                  sa[j-1]=c & mask;   c>>=bpe;   j++; }  
				sa[j-1]=c & mask;
			}
			
			if (!greater_(n,sa))
				sub_(sa,n);
			copy_(x,sa);
		}
		
	}
}