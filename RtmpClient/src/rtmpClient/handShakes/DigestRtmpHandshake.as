package rtmpClient.handShakes
{
	import com.hurlant.crypto.Crypto;
	import com.hurlant.crypto.rsa.RSAKey;
	import com.hurlant.crypto.symmetric.ICipher;
	import com.hurlant.math.BigInteger;
	import com.hurlant.util.Hex;
	import com.hurlant.util.der.DER;
	
	import flash.utils.ByteArray;
	import rtmpClient.utils.BigInt;
	import rtmpClient.utils.DiffieHellman;
	import rtmpClient.IRtmpHandshake;
	import rtmpClient.Utils;

	public class DigestRtmpHandshake implements IRtmpHandshake
	{
		public static const HANDSHAKE_SIZE:int = 1536;
		
		private static const DIGEST_SIZE:int = 32;
		private static const PUBLIC_KEY_SIZE:int = 128;
		
		private static const SERVER_CONST:ByteArray = stringToByteArray("Genuine Adobe Flash Media Server 001");
		public static const CLIENT_CONST:ByteArray = stringToByteArray("Genuine Adobe Flash Player 001");
		
		private static const RANDOM_CRUD:ByteArray = Hex.toArray(
			"F0EEC24A8068BEE82E00D0D1029E7E576EEC5D2D29806FAB93B8E636CFEB31AE"
		);
		
		private static const SERVER_CONST_CRUD:ByteArray = concatByteArray(SERVER_CONST, RANDOM_CRUD);
		
		private static const CLIENT_CONST_CRUD:ByteArray = concatByteArray(CLIENT_CONST, RANDOM_CRUD);
		
		private static const DH_MODULUS_BYTES:ByteArray = Hex.toArray(
			"FFFFFFFFFFFFFFFFC90FDAA22168C234C4C6628B80DC1CD129024E088A67CC74"
			+ "020BBEA63B139B22514A08798E3404DDEF9519B3CD3A431B302B0A6DF25F1437"
			+ "4FE1356D6D51C245E485B576625E7EC6F44C42E9A637ED6B0BFF5CB6F406B7ED"
			+ "EE386BFB5A899FA5AE9F24117C4B1FE649286651ECE65381FFFFFFFFFFFFFFFF"
		);
		
		private static const DH_MODULUS:BigInteger = new BigInteger(DH_MODULUS_BYTES, 1);
		
		private static const DH_BASE:BigInteger = BigInteger.nbv(2);
		
		private static function stringToByteArray(string:String):ByteArray {
			var byteArray:ByteArray = new ByteArray();
			byteArray.writeUTFBytes(string);
			return byteArray;
		}
		
		private static function concatByteArray(a:ByteArray, b:ByteArray):ByteArray {
			var c:ByteArray = new ByteArray();
			c.writeBytes(a);
			c.writeBytes(b);
			return c;
		}
		
		private static function calculateOffset(input:ByteArray, pointerIndex:int, modulus:int, increment:int):int {
			var oldInputPosition:int = input.position;
			
			var pointer:ByteArray = new ByteArray();
			input.position = pointerIndex;
			pointer.writeByte(input.readByte());
			pointer.writeByte(input.readByte());
			pointer.writeByte(input.readByte());
			pointer.writeByte(input.readByte());
			
			input.position = oldInputPosition;
			
			var offset:int = 0;
			// sum the 4 bytes of the pointer
			for (var i:int = 0; i < pointer.length; i++) {
				offset += pointer[i] & 0xff;
			}
			offset %= modulus;
			offset += increment;
			return offset;
		}
		
		private static function digestHandshake(input:ByteArray, digestOffset:int, key:ByteArray):ByteArray {
			input.position = 0;
			var message:ByteArray = new ByteArray();
			input.readBytes(message, 0, digestOffset);
			var afterDigestOffset:int = digestOffset + DIGEST_SIZE;
			input.position = afterDigestOffset;
			input.readBytes(message, digestOffset, HANDSHAKE_SIZE - afterDigestOffset);
			return Utils.sha256(message, key);
		}
		
		private static function generateRandomHandshake():ByteArray {
			var randomBytes:ByteArray = new ByteArray();
			while(randomBytes.length < HANDSHAKE_SIZE)
				randomBytes.writeByte(Math.random() * 0xFF);
			return randomBytes;
		}
		
		private static var clientVersionToValidationTypeMap:Object = {
			0x09007c02: 1,
			0x09009f02: 1,
			0x0900f602: 1,
			0x0a000202: 1,
			0x0a000c02: 1,
			0x80000302: 2,
			0x0a002002: 2
		}
		
		protected static function getValidationTypeForClientVersion(version:ByteArray):int {
			var intValue:int = version.readUnsignedInt();
			return clientVersionToValidationTypeMap[intValue] || 0;
		}
		
		private var clientVersionToUse:ByteArray = Utils.arrayToByteArray([0x09, 0x00, 0x7c, 0x02]);
		
		private var serverVersionToUse:ByteArray = Utils.arrayToByteArray([0x03, 0x05, 0x01, 0x01]);
		
		private static function calculateDigestOffset(input:ByteArray, validationType:int):int {
			switch(validationType) {
				case 1: return calculateOffset(input, 8, 728, 12);
				case 2: return calculateOffset(input, 772, 728, 776);
				default: throw new Error("cannot get digest offset for type: " + validationType);
			}
		}
		
		private static function publicKeyOffset(input:ByteArray, validationType:int):int {
			switch(validationType) {
				case 1: return calculateOffset(input, 1532, 632, 772);
				case 2: return calculateOffset(input, 768, 632, 8);
				default: throw new Error("cannot get public key offset for type: " + validationType);
			}
		}
		
		//==========================================================================
		
		//private KeyAgreement keyAgreement;
		private var peerVersion:ByteArray;
		private var ownPublicKey:ByteArray;
		private var peerPublicKey:ByteArray;
		private var ownPartOneDigest:ByteArray;
		private var peerPartOneDigest:ByteArray;
		private var cipherOut:ICipher;
		private var cipherIn:ICipher;
		private var peerTime:ByteArray;
		
		private var rtmpe:Boolean;
		private var validationType:int;
		
		private var swfHash:ByteArray;
		private var swfSize:int;
		private var swfvBytes:ByteArray;
		
		private var peerPartOne:ByteArray;
		private var ownPartOne:ByteArray;
		
		public function DigestRtmpHandshake(isRtmpe:Boolean = false, swfHash:ByteArray = null, swfSize:int = 0, clientVersionToUse:ByteArray = null) {
			this.rtmpe = isRtmpe;// session.isRtmpe();
			this.swfHash = swfHash;// session.getSwfHash();
			this.swfSize = swfSize;// session.getSwfSize();
			if(clientVersionToUse != null) {
				this.clientVersionToUse = clientVersionToUse; //session.getClientVersionToUse();
			}
		}
		
		public function getSwfvBytes():ByteArray {
			return swfvBytes;
		}
		
		public function getCipherIn():ICipher {
			return cipherIn;
		}
		
		public function getCipherOut():ICipher {
			return cipherOut;
		}
		
		public function isRtmpe():Boolean {
			return rtmpe;
		}
		
		public function getPeerVersion():ByteArray {
			return peerVersion;
		}
		
		//========================= ENCRYPT / DECRYPT ==============================
		
		private function cipherUpdate(input:ByteArray, cipher:ICipher):void {
			var size:int = input.length;
			if(size == 0) {
				return;
			}
			var position:int = input.position;
			var bytes:ByteArray = new ByteArray();
			input.readBytes(bytes, position);
			cipher.encrypt(bytes);
			input.writeBytes(bytes, position);
		}
		
		public function cipherUpdateIn(input:ByteArray):void {
			cipherUpdate(input, cipherIn);
		}
		
		public function cipherUpdateOut(input:ByteArray):void {
			cipherUpdate(input, cipherOut);
		}
		
		//============================== PKI =======================================
		
		private var dh:DiffieHellman = new DiffieHellman();
		private var dh_X:BigInt;
		
		private function initKeyPair():void {
			dh = new DiffieHellman();
			
			var e:BigInt = dh.getE();
			var hex:String = BigInt.bigInt2str(e, 16);
			
			
			var temp:ByteArray = Hex.toArray(hex);
			
			ownPublicKey = new ByteArray();
			
			while(temp.length + ownPublicKey.length < PUBLIC_KEY_SIZE)
				ownPublicKey.writeByte(0);
						
			while(ownPublicKey.length < PUBLIC_KEY_SIZE)
				ownPublicKey.writeByte(temp.readByte());
			
			
			/*final DHParameterSpec keySpec = new DHParameterSpec(DH_MODULUS, DH_BASE);
			final KeyPair keyPair;
			try {
				KeyPairGenerator keyGen = KeyPairGenerator.getInstance("DH");
				keyGen.initialize(keySpec);
				keyPair = keyGen.generateKeyPair();
				keyAgreement = KeyAgreement.getInstance("DH");
				keyAgreement.init(keyPair.getPrivate());
			} catch (Exception e) {
				throw new RuntimeException(e);
			}
			// extract public key bytes
			DHPublicKey publicKey = (DHPublicKey) keyPair.getPublic();
			BigInteger dh_Y = publicKey.getY();
			ownPublicKey = dh_Y.toByteArray();
			byte[] temp = new byte[PUBLIC_KEY_SIZE];
			if (ownPublicKey.length < PUBLIC_KEY_SIZE) {
				// pad zeros on left
				System.arraycopy(ownPublicKey, 0, temp, PUBLIC_KEY_SIZE - ownPublicKey.length, ownPublicKey.length);
				ownPublicKey = temp;
			} else if (ownPublicKey.length > PUBLIC_KEY_SIZE) {
				// truncate zeros from left
				System.arraycopy(ownPublicKey, ownPublicKey.length - PUBLIC_KEY_SIZE, temp, 0, PUBLIC_KEY_SIZE);
				ownPublicKey = temp;
			}*/
		}
		
		private function initCiphers():void {
			var otherPublicKeyInt:BigInt = new BigInt(Utils.byteArrayToArray(peerPublicKey));
			var k:BigInt = dh.getK(otherPublicKeyInt);
			
			/*var otherPublicKeyInt:BigInteger = new BigInteger(peerPublicKey, 1);
						
			try {
				RSAKey.generate(otherPublicKeyInt.
				KeyFactory keyFactory = KeyFactory.getInstance("DH");
				KeySpec otherPublicKeySpec = new DHPublicKeySpec(otherPublicKeyInt, DH_MODULUS, DH_BASE);
				PublicKey otherPublicKey = keyFactory.generatePublic(otherPublicKeySpec);
				keyAgreement.doPhase(otherPublicKey, true);
			} catch (e:Error) {
				throw new Error(e);
			}*/
						
			var sharedSecret:ByteArray = Hex.toArray(BigInt.bigInt2str(k, 16)); //byte[] sharedSecret = keyAgreement.generateSecret();
			var digestOut:ByteArray = Utils.sha256(peerPublicKey, sharedSecret);
			var digestIn:ByteArray = Utils.sha256(ownPublicKey, sharedSecret);
			
			try {
				cipherOut = Crypto.getCipher("rc4", digestOut);
				/*cipherOut = Cipher.getInstance("RC4");
				cipherOut.init(Cipher.ENCRYPT_MODE, new SecretKeySpec(digestOut, 0, 16, "RC4"));*/
				cipherIn = Crypto.getCipher("rc4", digestIn);
				/*cipherIn = Cipher.getInstance("RC4");
				cipherIn.init(Cipher.DECRYPT_MODE, new SecretKeySpec(digestIn, 0, 16, "RC4"));*/
				//logger.info("initialized encryption / decryption ciphers");
			} catch (e:Error) {
				throw new Error(e);
			}
			// update 'encoder / decoder state' for the RC4 keys
			// both parties *pretend* as if handshake part 2 (1536 bytes) was encrypted
			// effectively this hides / discards the first few bytes of encrypted session
			// which is known to increase the secure-ness of RC4
			// RC4 state is just a function of number of bytes processed so far
			// that's why we just run 1536 arbitrary bytes through the keys below
			var dummyBytes:ByteArray = new ByteArray();
			cipherIn.decrypt(dummyBytes);
			cipherOut.encrypt(dummyBytes);
			/*byte[] dummyBytes = new byte[HANDSHAKE_SIZE];
			cipherIn.update(dummyBytes);
			cipherOut.update(dummyBytes);*/
		}
		
		//============================== CLIENT ====================================
		
		public function encodeClient0():ByteArray {
			var out:ByteArray = new ByteArray();
			if (rtmpe) {
				out.writeByte(0x06);
			} else {
				out.writeByte(0x03);
			}
			return out;
		}
		
		public function encodeClient1():ByteArray {
			var out:ByteArray = generateRandomHandshake();
			out.position = 0;
			out.writeByte(0);
			out.writeByte(0);
			out.writeBytes(clientVersionToUse);
			clientVersionToUse.position = 0;
			validationType = getValidationTypeForClientVersion(clientVersionToUse);
			//logger.info("using client version {}", Utils.toHex(clientVersionToUse));
			if (validationType == 0) {
				ownPartOne = Utils.cloneByteArray(out); // save for later
				return out;
			}
			//logger.debug("creating client part 1, validation type: {}", validationType);
			initKeyPair();
			var publicKeyOffset:int = publicKeyOffset(out, validationType);
			out.writeByte(publicKeyOffset);
			out.writeBytes(ownPublicKey);
			var digestOffset:int = calculateDigestOffset(out, validationType);
			ownPartOneDigest = digestHandshake(out, digestOffset, CLIENT_CONST);
			out.position = digestOffset;
			out.writeBytes(ownPartOneDigest);
			return out;
		}
		
		public function decodeServerAll(input:ByteArray):Boolean {
			decodeServer0(input.readByte());
			
			var bytes1:ByteArray = new ByteArray();
			input.readBytes(bytes1, 0, HANDSHAKE_SIZE);
			decodeServer1(bytes1);
			
			var bytes2:ByteArray = new ByteArray();
			input.readBytes(bytes2, 0, HANDSHAKE_SIZE);
			decodeServer2(bytes2);
			
			return true;
		}
		
		private function decodeServer0(byte:int):void {
			if(rtmpe &&  byte != 0x06) {
				//logger.warn("server does not support rtmpe! falling back to rtmp");
				rtmpe = false;
			}
		}
		
		private function decodeServer1(input:ByteArray):void {
			peerTime = new ByteArray();
			input.readBytes(peerTime, 0, 4);
			
			var serverVersion:ByteArray = new ByteArray();
			input.readBytes(serverVersion, 0, 4);

			//logger.debug("server time: {}, version: {}", Utils.toHex(peerTime), Utils.toHex(serverVersion));
			if(swfHash != null) {
				// swf verification
				var key:ByteArray = new ByteArray();// new byte[DIGEST_SIZE];
				input.readBytes(key, 0, HANDSHAKE_SIZE - DIGEST_SIZE);
				var digest:ByteArray = Utils.sha256(swfHash, key);
				// construct SWF verification pong payload
				var swfv:ByteArray = new ByteArray();// ChannelBuffers.buffer(42);
				swfv.writeByte(0x01);
				swfv.writeByte(0x01);
				swfv.writeInt(swfSize);
				swfv.writeInt(swfSize);
				swfv.writeBytes(digest);
				
				swfvBytes = new ByteArray(); //new byte[42];
				swfvBytes.writeBytes(swfv, 0, 42);
				
				//logger.info("calculated swf verification response: {}", Utils.toHex(swfvBytes));
			}
			if(validationType == 0) {
				peerPartOne = input; // save for later
				return;
			}
			
			//logger.debug("processing server part 1, validation type: {}", validationType);
			var digestOffset:int = calculateDigestOffset(input, validationType);
			var expected:ByteArray = digestHandshake(input, digestOffset, SERVER_CONST);
			peerPartOneDigest = new ByteArray(); //new byte[DIGEST_SIZE];
			input.position = digestOffset;
			input.readBytes(peerPartOneDigest, 0, DIGEST_SIZE);
			if (!Utils.byteArrayAreEquals(peerPartOneDigest, expected)) {
				var altValidationType:int = validationType == 1 ? 2 : 1;
				/*logger.warn("server part 1 validation failed for type {}, will try with type {}",
					validationType, altValidationType);*/
				digestOffset = calculateDigestOffset(input, altValidationType);
				expected = digestHandshake(input, digestOffset, SERVER_CONST);
				peerPartOneDigest = new ByteArray(); // new byte[DIGEST_SIZE];
				input.position = digestOffset;
				input.readBytes(peerPartOneDigest, 0, DIGEST_SIZE);
				if (!Utils.byteArrayAreEquals(peerPartOneDigest, expected)) {
					throw new Error("server part 1 validation failed even for type: " + altValidationType);
				}
				validationType = altValidationType;
			}
			//logger.info("server part 1 validation success");
			peerPublicKey = new ByteArray(); //new byte[PUBLIC_KEY_SIZE];
			var publicKeyOffset:int = publicKeyOffset(input, validationType);
			input.position = publicKeyOffset;
			input.readBytes(peerPublicKey, 0, PUBLIC_KEY_SIZE);
			initCiphers();
		}
		
		private function decodeServer2(input:ByteArray):void {
			if(validationType == 0) {
				return; // TODO validate random echo
			}
			//logger.debug("processing server part 2 for validation");
			var key:ByteArray = Utils.sha256(ownPartOneDigest, SERVER_CONST_CRUD);
			var digestOffset:int = HANDSHAKE_SIZE - DIGEST_SIZE;
			var expected:ByteArray = digestHandshake(input, digestOffset, key);
			var actual:ByteArray = new ByteArray(); //new byte[DIGEST_SIZE];
			input.position = digestOffset;
			input.readBytes(actual, 0, DIGEST_SIZE);
			if (!Utils.byteArrayAreEquals(actual, expected)) {
				throw new Error("server part 2 validation failed");
			}
			//logger.info("server part 2 validation success");
		}
		
		public function encodeClient2():ByteArray {
			if(validationType == 0) {
				peerPartOne.writeBytes(peerTime);
				peerPartOne.writeInt(4);
				peerPartOne.writeInt(0);
				return peerPartOne;
			}
			//logger.debug("creating client part 2 for validation");
			var out:ByteArray = generateRandomHandshake();
			var key:ByteArray = Utils.sha256(peerPartOneDigest, CLIENT_CONST_CRUD);
			var digestOffset:int = HANDSHAKE_SIZE - DIGEST_SIZE;
			var digest:ByteArray = digestHandshake(out, digestOffset, key);
			out.position = digestOffset;
			out.writeBytes(digest);
			return out;
		}
	}
}