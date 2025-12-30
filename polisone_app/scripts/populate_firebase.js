// Firebase Admin SDK script to populate test data
// Run with: node populate_firebase.js

const admin = require('firebase-admin');

// Initialize Firebase Admin
const serviceAccount = {
  projectId: "polisone-b1179",
  // You'll need to download service account key from Firebase Console
};

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const auth = admin.auth();
const db = admin.firestore();

// Test users to create
const users = [
  { email: 'admin@polisone.com', password: 'Admin@123', role: 'admin' },
  { email: 'officer1@polisone.com', password: 'Officer@123', role: 'officer' },
  { email: 'officer2@polisone.com', password: 'Officer@123', role: 'officer' },
  { email: 'officer3@polisone.com', password: 'Officer@123', role: 'officer' },
];

// Test officers to create
const officers = [
  {
    id: 'officer-001',
    name: 'Unit-12 (Sharma)',
    status: 'on_patrol',
    latitude: 19.0860,
    longitude: 72.8877,
    current_location: 'Andheri West',
    badge_number: 'MH-1234',
    last_updated: admin.firestore.FieldValue.serverTimestamp()
  },
  {
    id: 'officer-002',
    name: 'Unit-08 (Patel)',
    status: 'responding',
    latitude: 19.0660,
    longitude: 72.8677,
    current_location: 'Bandra',
    badge_number: 'MH-1235',
    last_updated: admin.firestore.FieldValue.serverTimestamp()
  },
  {
    id: 'officer-003',
    name: 'Unit-15 (Kumar)',
    status: 'on_patrol',
    latitude: 19.0760,
    longitude: 72.8977,
    current_location: 'Juhu',
    badge_number: 'MH-1236',
    last_updated: admin.firestore.FieldValue.serverTimestamp()
  },
  {
    id: 'officer-004',
    name: 'Unit-22 (Singh)',
    status: 'on_patrol',
    latitude: 19.0960,
    longitude: 72.8577,
    current_location: 'Powai',
    badge_number: 'MH-1237',
    last_updated: admin.firestore.FieldValue.serverTimestamp()
  },
  {
    id: 'officer-005',
    name: 'Unit-05 (Desai)',
    status: 'responding',
    latitude: 19.0180,
    longitude: 72.8479,
    current_location: 'Dadar',
    badge_number: 'MH-1238',
    last_updated: admin.firestore.FieldValue.serverTimestamp()
  },
  {
    id: 'officer-006',
    name: 'Unit-18 (Mehta)',
    status: 'off_duty',
    latitude: 18.9220,
    longitude: 72.8347,
    current_location: 'Colaba',
    badge_number: 'MH-1239',
    last_updated: admin.firestore.FieldValue.serverTimestamp()
  }
];

async function createUsers() {
  console.log('Creating users...');
  for (const user of users) {
    try {
      const userRecord = await auth.createUser({
        email: user.email,
        password: user.password,
        emailVerified: true
      });
      console.log(`✅ Created user: ${user.email}`);
    } catch (error) {
      if (error.code === 'auth/email-already-exists') {
        console.log(`⚠️  User already exists: ${user.email}`);
      } else {
        console.error(`❌ Error creating ${user.email}:`, error.message);
      }
    }
  }
}

async function createOfficers() {
  console.log('\nCreating officers...');
  for (const officer of officers) {
    try {
      await db.collection('officers').doc(officer.id).set(officer);
      console.log(`✅ Created officer: ${officer.name}`);
    } catch (error) {
      console.error(`❌ Error creating ${officer.name}:`, error.message);
    }
  }
}

async function main() {
  try {
    await createUsers();
    await createOfficers();
    console.log('\n✅ All test data created successfully!');
    console.log('\nYou can now:');
    console.log('1. Login with: admin@polisone.com / Admin@123');
    console.log('2. See 6 officers on the map');
    console.log('3. Watch real-time updates!');
  } catch (error) {
    console.error('Error:', error);
  } finally {
    process.exit(0);
  }
}

main();
