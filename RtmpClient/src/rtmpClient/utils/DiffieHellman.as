package rtmpClient.utils
{

	public class DiffieHellman
	{
		public var debugCrypt:Boolean = true;
		
		//Second Oakley Grp - RFC2409
		/* Prime:
		FFFFFFFF FFFFFFFF C90FDAA2 2168C234 C4C6628B 80DC1CD1
		29024E08 8A67CC74 020BBEA6 3B139B22 514A0879 8E3404DD
		EF9519B3 CD3A431B 302B0A6D F25F1437 4FE1356D 6D51C245
		E485B576 625E7EC6 F44C42E9 A637ED6B 0BFF5CB6 F406B7ED
		EE386BFB 5A899FA5 AE9F2411 7C4B1FE6 49286651 ECE65381
		FFFFFFFF FFFFFFFF
		
		Generator: 2
		
		*/
		
		private var s_prime_2:String = "FFFFFFFFFFFFFFFFC90FDAA22168C234C4C6628B80DC1CD129024E088A67CC74020BBEA63B139B22514A08798E3404DDEF9519B3CD3A431B302B0A6DF25F14374FE1356D6D51C245E485B576625E7EC6F44C42E9A637ED6B0BFF5CB6F406B7EDEE386BFB5A899FA5AE9F24117C4B1FE649286651ECE65381FFFFFFFFFFFFFFFF";
		private var s_gen_2:String = "2";
		
		private var s_prime_RFC5114_2_1:String = "B10B8F96A080E01DDE92DE5EAE5D54EC52C99FBCFB06A3C69A6A9DCA52D23B616073E28675A23D189838EF1E2EE652C013ECB4AEA906112324975C3CD49B83BFACCBDD7D90C4BD7098488E9C219A73724EFFD6FAE5644738FAA31A4FF55BCCC0A151AF5F0DC8B4BD45BF37DF365C1A65E68CFDA76D4DA708DF1FB2BC2E4A4371";
		private var s_gen_RFC5114_2_1:String = "A4D1CBD5C3FD34126765A442EFB99905F8104DD258AC507FD6406CFF14266D31266FEA1E5C41564B777E690F5504F213160217B4B01B886A5E91547F9E2749F4D7FBD7D3B9A92EE1909D0D2263F80A76A6A24C087A091F531DBF0A0169B6A28AD662A4D18E73AFA32D779D5918D08BC8858F4DCEF97C2A24855E6EEB22B3B2E5";
		
		//private var s_gen:String, s_prime:String;
		private var _g:BigInt;
		private var _p:BigInt;
		private var _mode:String;
		private var _e:BigInt;
		private var _x:BigInt;
		private var _K:BigInt;
		public function DiffieHellman()
		{
			setMode("diffie-hellman-group1-sha1");
		}
		
		public function setMode(mode:String):Boolean{
			_mode = mode;
			_e = null;
			if(mode == "diffie-hellman-group1-sha1"){
				//s_gen = s_gen_2;
				//s_prime = s_prime_2;
				_g = BigInt.str2bigInt(s_gen_2,16,0);
				_p = BigInt.str2bigInt(s_prime_2,16,0);
				return true;
			}
			//diffie-hellman-group14-sha1
			return false;
		}
		/*
		1) DiffieHellman()
		2) setMode()   g, p
		3) generateX   x
		4) computeE  e= g^x mod p  : PUBLIC = getE
		5) send e
		6) receive (K_S || f || s)   (s = sig)
		7) verify K_S manually (or if stored previous
		8) computeE  K = f^x mod p
		9) computeH H = hash(V_C || V_S || I_C || I_S || K_S || e || f || K)
		V_C/V_S are identification strings from client, server
		I_C/I_S are the KEXINIT messages from client, server
		10) verify s is sig for H, using pub key K_S
		*/
		
		private function expmod(g:BigInt, x:BigInt, p:BigInt):BigInt{
			if(debugCrypt) trace("Doing expmod - please wait...");
			var e_temp:BigInt;
			
			//e = g^x mod p
			e_temp = BigInt.powMod(g, x, p);		
			if(debugCrypt) trace("   DONE");
			return e_temp;
		}
		public function generateX():BigInt{
			//TODO: Use rand
			var s_x:String = "f5dece7e1e0feaa060a0c48ce289943d1bcabd52f354fa38803706e001b8203102ab29f99c744473082872ab5f4c8112e32803d0f98c34e007c5e6bf3a1bb32175e273724def7530c772d1350f7006ca105949c6cf74aaf6651968c271c541afce32afcfff68e6aa322761317b0abde4b79b4b3a4e03529e6c81d23ddb816f8cde38d52d9dae4ef130421b71af8765478a812bb1cd3900411f6d38467bdbcdb6cf20d731503c850c04584441e65028095123a11c23e7f0ee49c0ad1feab3a3449f4e82e7fb0ddb12729cea1c8167a38c212385b275183634d138c104115b84adabb574270a1ae1b9fb1fa9a31f53b685cd615f9c49907356cbbd329166e33eef70c4ad5806d96fb8ba61eaff382e7453a95b8d178ca5962fcd83b96c33e8a49bd6709bb44890ce800f0971a37d9144ac57d69203134e3e3cd8d0b14fea7ea336251cce68689ba96dcb79a52d7221b29e9336d157bacb195698408a92c7859ca065a02cded85e928d9a1497133492c9a341f59a3c4ce15384b56fdfd13786cd5fb6c4aa4de6bd29d5faf1e72afa8b3091abdebe4f00e372282e38d2a937e59ec724b6f419941139900439a281741ef0de3ad5ab9187b852c3563305ba0346fa6947cef86a35efeca4e94e8df3d4bb553388ee404e0fa0e585d22e24c03be389cb814b01acc9bd3ed10e1600a8d02589c5bbae4f65c5679078c23591d25180a8b0";
			var x:BigInt = BigInt.str2bigInt(s_x,16,0);
			return x;
		}
		public function getE():BigInt{
			if(_x ==null) _x = generateX();
			if(_e == null){
				_e = expmod(_g,_x,_p);
			} 
			return _e;
		}
		public function getK(f:BigInt):BigInt{
			// K = f^x mod p
			if(_K == null){
				_K = expmod(f,_x,_p);
			} 
			return _K;
		}
		
		
		
		public function checkDH_RFC5114_2_1():Boolean{
			//sample rands - 512bit
			var s_x:String = "B9A3B3AE8FEFC1A2930496507086F8455D48943E";
			var s_y:String = "9392C9F9EB6A7A6A9022F7D83E7223C6835BBDDA";
			
			return checkDH(s_x, s_y, s_gen_RFC5114_2_1, s_prime_RFC5114_2_1);
		}	
		public function checkDH_Grp2():Boolean{
			//sample rands - 512bit
			var s_x:String = "f5dece7e1e0feaa060a0c48ce289943d1bcabd52f354fa38803706e001b8203102ab29f99c744473082872ab5f4c8112e32803d0f98c34e007c5e6bf3a1bb32175e273724def7530c772d1350f7006ca105949c6cf74aaf6651968c271c541afce32afcfff68e6aa322761317b0abde4b79b4b3a4e03529e6c81d23ddb816f8cde38d52d9dae4ef130421b71af8765478a812bb1cd3900411f6d38467bdbcdb6cf20d731503c850c04584441e65028095123a11c23e7f0ee49c0ad1feab3a3449f4e82e7fb0ddb12729cea1c8167a38c212385b275183634d138c104115b84adabb574270a1ae1b9fb1fa9a31f53b685cd615f9c49907356cbbd329166e33eef70c4ad5806d96fb8ba61eaff382e7453a95b8d178ca5962fcd83b96c33e8a49bd6709bb44890ce800f0971a37d9144ac57d69203134e3e3cd8d0b14fea7ea336251cce68689ba96dcb79a52d7221b29e9336d157bacb195698408a92c7859ca065a02cded85e928d9a1497133492c9a341f59a3c4ce15384b56fdfd13786cd5fb6c4aa4de6bd29d5faf1e72afa8b3091abdebe4f00e372282e38d2a937e59ec724b6f419941139900439a281741ef0de3ad5ab9187b852c3563305ba0346fa6947cef86a35efeca4e94e8df3d4bb553388ee404e0fa0e585d22e24c03be389cb814b01acc9bd3ed10e1600a8d02589c5bbae4f65c5679078c23591d25180a8b0";
			var s_y:String = "4d252b4a839c770debabf30b39d4f446546b1a8c69765f5f8392c685c4acb5c4cf4dc1c9c0cdbce51a029cc8105ef643a75f4c19530139421e7c149c6fef2c8ed9b3e9873aafddb3fe53e7ad25039d3a07ea70dbd5809ff83171e6eea9755b8f3eb75c4a98477e8d3f6b927a07a36168038f870d0e6eae82bc514dcc67705c371587cac58200b604dfa98b149b9fc2a16b6f46a635b1542af7aeb0d808de165123a2fc540e8d9e67c18c5ce7d69a1c79c1f145890ec865c5e77c4550951072b27346c66bed003440835d0387f0e15af6bfca82dba70c2e55c2093824efd9b0a9aedd445a5a533ec980e45b24e84e159c9bbe31deadfc3249d6836e4c3417174a086a7c46adfd0d07510af2cd0b8d6e25a76347294dc999db899c5d7a7ebd7931c8d907f4649ce682a9fc38b798e44011e05fb4524865f914f3fa7e92377f19a4fc72bf57e5d678746d0fca15dd2b9f81b9596cc3ec8efc130f559139da91b46182857cb79b266840dce3714166360d1bd4ab768fec7bfbaf7abd3c9c86cbe411ebc9a362c08ff5a64971e16f451da6d40dd9c10225e62a62b89a24ebeef7cc4cd2f09c0eb8b7ff0f81c933c81b65326c8cfe97463f166defbfe261842603322dfb51e680376f239674fb9b9fedacb08781f9ad63b16c6121ecdb99789c3c561605bfa5ec179417d38e96f0ebccfe36ca081042652905be5e4f1ce51f2ed5adad";
			
			return checkDH(s_x, s_y, s_gen_2, s_prime_2);
		}	
		public function checkDH(s_x:String, s_y:String, s_g:String, s_p:String):Boolean{
			if(debugCrypt) trace("Doing checkDH...");
			var x:BigInt = BigInt.str2bigInt(s_x,16,0);
			var y:BigInt = BigInt.str2bigInt(s_y,16,0);
			var g:BigInt = BigInt.str2bigInt(s_g,16,0);
			var p:BigInt = BigInt.str2bigInt(s_p,16,0);
			if(debugCrypt){
				trace("Using:");
				trace("x = "+BigInt.bigInt2str(x,16));
				trace("y = "+BigInt.bigInt2str(y,16));
				trace("g = "+BigInt.bigInt2str(g,16));
				trace("p = "+BigInt.bigInt2str(p,16));
			} 
			
			if(debugCrypt) trace("   Calculating e:");
			var e:BigInt = expmod(g, x, p);
			if(debugCrypt) trace("e="+BigInt.bigInt2str(e,16)+"\n   Calculating f:");
			var f:BigInt = expmod(g, y, p);
			if(debugCrypt) trace("f="+BigInt.bigInt2str(f,16)+"\n   Calculating Ks:");
			var Ks:BigInt = expmod(e, y, p);
			if(debugCrypt) trace("Ks="+BigInt.bigInt2str(Ks,16)+"\n   Calculating Kc:");
			var Kc:BigInt = expmod(f, x, p);
			if(debugCrypt) trace("Kc="+BigInt.bigInt2str(Kc,16)+"");
			
			if(BigInt.equals(Ks,Kc)) return true;
			return false;
		}
		public function checkPrimeGen():Boolean{
			//fails at the moment...
			if(debugCrypt) trace("Doing checkPrimeGen");
			var prime_2:BigInt = BigInt.str2bigInt(s_prime_2,16,0);
			var l:BigInt = BigInt.mod(prime_2, BigInt.str2bigInt("24",10,0));
			return BigInt.equals(l, BigInt.str2bigInt("11",10,0));
		}
		
	}
}