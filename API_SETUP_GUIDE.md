# LyoApp API Setup Guide

## Overview
Your LyoApp requires several APIs for full functionality. This guide provides step-by-step instructions for obtaining and integrating each required API.

## Required APIs

### 1. 🤖 OpenAI API (CRITICAL - Primary AI Service)
**Purpose**: Powers Lyo AI assistant, chat responses, course generation
**Website**: https://platform.openai.com/api-keys
**Cost**: Pay-per-token (~$0.01-0.06 per 1K tokens)

**Setup Steps**:
1. Visit https://platform.openai.com/api-keys
2. Create an OpenAI account or sign in
3. Verify your email and phone number
4. Add a payment method (required for API access)
5. Click "Create new secret key"
6. Copy the key and add it to `LyoConfiguration.swift`:
   ```swift
   static let openAIAPIKey = "sk-your-actual-api-key-here"
   ```
7. Set usage limits to control costs (recommended: $10/month initially)

**Integration Points in Your App**:
- `AIAvatarIntegration.swift` - AI avatar conversations
- `AIOnboardingFlowView.swift` - Course generation
- `SimpleChatView.swift` - Chat responses
- `LearnView.swift` - Learning assistance

### 2. 🎤 Speech Recognition (Already Integrated)
**Purpose**: "Hey Lyo" voice activation and voice input
**API**: iOS built-in `SFSpeechRecognizer`
**Cost**: FREE
**Status**: ✅ Already implemented in your app

**Files Using This**:
- `VoiceRecognizer.swift`
- `VoiceActivationService.swift`

### 3. 🔊 Text-to-Speech (Already Available)
**Purpose**: Lyo speaking responses
**API**: iOS built-in `AVSpeechSynthesizer`
**Cost**: FREE
**Status**: ✅ Ready to implement

### 4. 🔐 Authentication API (Recommended)
**Purpose**: User registration, login, profile management
**Options**:

#### Option A: Firebase Auth (Recommended)
**Website**: https://firebase.google.com/products/auth
**Cost**: FREE for most usage

**Setup Steps**:
1. Go to https://console.firebase.google.com/
2. Create new project → "LyoApp"
3. Enable Authentication → Sign-in methods → Email/Password
4. Download `GoogleService-Info.plist`
5. Add to your Xcode project
6. Install Firebase SDK via Swift Package Manager:
   ```
   https://github.com/firebase/firebase-ios-sdk
   ```

#### Option B: Auth0
**Website**: https://auth0.com/
**Cost**: FREE for up to 7,000 active users

### 5. 💾 Database API (Recommended)
**Purpose**: Store user progress, courses, conversations

#### Option A: Firebase Firestore (Recommended)
**Website**: https://firebase.google.com/products/firestore
**Cost**: FREE tier available

#### Option B: Supabase
**Website**: https://supabase.com/
**Cost**: FREE tier available

### 6. 📊 Analytics API (Optional)
**Purpose**: Track learning progress, user engagement
**Options**:
- Firebase Analytics (FREE)
- Mixpanel
- Amplitude

## Current Backend Integration

Your app already has a local backend server in `simple_backend.py`. To use it:

1. **Start the backend**:
   ```bash
   cd "/Users/republicalatuya/Desktop/LyoApp July"
   python simple_backend.py
   ```

2. **The backend provides**:
   - Health checks
   - User authentication
   - Message handling
   - WebSocket connections

## Integration Priority

### Phase 1: Essential (Get AI Working)
1. ✅ OpenAI API - **Get this first for Lyo to work**
2. ✅ Start local backend server
3. ✅ Test Quantum Learning Gate button

### Phase 2: User Management
1. Firebase Auth setup
2. User profiles and progress tracking
3. Cloud data synchronization

### Phase 3: Advanced Features
1. Analytics integration
2. Push notifications
3. Advanced AI features

## Testing Your Integration

After adding the OpenAI API key:

1. **Test the Quantum Learning Gate button**:
   - Tap the enhanced "Lyo" button
   - Check if AI responses work

2. **Test voice activation**:
   - Say "Hey Lyo"
   - Verify voice recognition works

3. **Test backend connection**:
   - Start the backend server
   - Check WebSocket connections

## Security Best Practices

1. **Never commit API keys to Git**:
   - Add API keys to `.gitignore`
   - Use environment variables in production

2. **Use secure storage**:
   - Store sensitive data in iOS Keychain
   - Implement proper token refresh

3. **Set usage limits**:
   - Monitor API usage
   - Set spending limits on API providers

## Cost Estimates

| Service | Free Tier | Paid Pricing |
|---------|-----------|-------------|
| OpenAI API | $5 credit | ~$10-50/month |
| Firebase | Generous free tier | $25/month+ |
| Speech APIs | iOS built-in FREE | N/A |

## Next Steps

1. **Get OpenAI API key first** - this is critical for Lyo to function
2. Start with local backend for development
3. Add Firebase for production user management
4. Monitor usage and costs

## Support

If you encounter issues:
1. Check the console logs in Xcode
2. Verify API keys are correctly configured
3. Ensure backend server is running
4. Check network connectivity

---

**Important**: I cannot automatically obtain API keys for you due to security requirements. Each API provider requires manual account creation, verification, and billing setup.
