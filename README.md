### README for ArbiChat

---

# **ArbiChat**  
A decentralized messaging app with integrated cryptocurrency functionalities, designed for secure communication, seamless transactions, and a trust-driven community.  

---

## **Overview**  
ArbiChat combines decentralized identifiers, real-time messaging, and blockchain-enabled tipping, empowering users with crypto anonymity while ensuring ease of interaction and verifiability.

---

## **Features**  
### **1. Onboarding & Wallet Setup**  
- **Private Key Management:**  
  - Users are onboarded via Web3Auth, which generates a unique private key stored securely in SharedPreferences.  
- **Data Storage:**  
  - Wallet addresses and emails are saved to Cloud Firestore, ensuring streamlined user identification while preserving decentralization.  
- **Balance Retrieval:**  
  - The app uses Web3dart and a Web3 client to fetch and display wallet balances in real-time.  

### **2. Real-Time Messaging**  
- **Secure Messaging:**  
  - Messages are stored in and retrieved from Cloud Firestore, enabling reliable and real-time communication.  
- **Decentralized Identifiers:**  
  - Wallet addresses function as unique, blockchain-based user identifiers.  

### **3. Optional Verification System**  
- **Trust Score:**  
  - Users will be able to verify their identity by affirming the name associated with their wallet address. Verified identities increase the trust score, allowing for safer one-on-one interactions.  
- **Human Protocol-Inspired:**  
  - This feature encourages trust-based transactions and enhances user credibility within the app.  

### **4. Tipping Functionality**  
- **Crypto Tips Made Easy:**  
  - Users can send tips directly to another wallet address using the private key stored locally.  
- **Transaction Security:**  
  - Web3dart ensures secure and hassle-free transactions between verified users.  

### There's honestly a whole lot that I have in mind to add, but because of the constraint of time, I have to submit this as is.

---

## **Walkthrough**  

- **Watch the Full Walkthrough Video Here:**  
  *[![ArbiChat Walkthrough](https://img.youtube.com/vi/FrANv7GnACM/0.jpg)]((https://www.youtube.com/watch?v=FrANv7GnACM))*
  
- **Transaction sent during walkthrough:**
  *![Completed Transaction Proof](assets/arbitrum-video-transaction.png)*
  
- **Screenshots of Features:**  
  1. **Cloud Firestore Database View:**  
     - *![Cloud FireStore](assets/arbitrum-database=cloud-firestore.png)*  
  2. **Cloud Firestore Document Example:**  
     - *![Cloud Firestore](assets/arb-database-two.png)*  

---

## **Download the APK**  
You can download the latest APK directly from this repository:  
- [[Download APK](https://github.com/0xiammatrixx/flutter_quick_start/releases/download/v1.0.0-alpha/ArbiChat.v1.0.0.apk)](#)

---

## **Tech Stack**  
- **Frontend:** Flutter  
- **Backend:** Firebase (Cloud Firestore, Storage)  
- **Blockchain:** Web3Auth, Web3dart  
- **Storage:** SharedPreferences  

---

## **Contributing**  
Feel free to fork the repository, raise issues, or submit pull requests for improvements and features.  

---

## **License**  
MIT License.  

---
