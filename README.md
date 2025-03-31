# HearU - AI-Powered Mental Health App

**Empowering mental wellness through AI and community support.**

Struggling with mental health? HearU is here to help. Our AI-powered app offers daily wellness tasks, personalized AI-driven support, and a unique peer connection system to keep you motivated, track your well-being, and connect you with others facing similar challenges.

---

## 🌟 Features

- **Daily Wellness Tasks**  
  Randomized activities like breathing exercises, articles, and sleep sounds to inspire your day. Earn points to unlock more content!

- **AI Chat Support**  
  Get personalized mental health guidance from our DeepSeek R1-powered chatbot.

- **Mood Tracking**  
  Answer periodic quizzes and check-ins to monitor your mental well-being, visualized in a historical mood graph.

- **Peer Support System**  
  Connect with others who understand your struggles via our vector-based recommendation system.

- **Profile Customization**  
  Add personal descriptions and tags to find peer matches that resonate with you.

---

## 🛠️ Technology Stack

- **Frontend**: Flutter  
- **Backend**: Hono, Drizzle ORM  
- **Database**: PostgreSQL with pgvector for vector embeddings  
- **Caching**: Redis (two instances: one for LLM chat storage, one for user-to-user chats)  
- **AI Models**:  
  - DeepSeek R1: LLM-based mental health chat and quizzes  
  - Gemini Flash 2: Text summarization  
  - Gemini Embedding 01: Vector embeddings  

---

## 🚀 How It Works

1. **Daily Task System**  
   Kick off your day with wellness tasks tailored to your needs.

2. **Mood Assessment**  
   Track your mood with a quick 5-question quiz and periodic check-ins.

3. **AI Chatbot Assistance**  
   Chat with our AI for real-time mental health support.

4. **Peer Matching**  
   Find like-minded peers using vector embeddings from your chat history and profile.

5. **User Engagement**  
   Earn points by completing tasks to unlock exciting new content.

---

## 📚 Setup & Installation

1. **Clone the Repository**  
   ```bash
   git clone https://github.com/your-repo/hearu.git
   ```

2. **Install Dependencies**  
   ```bash
   cd hearu
   bun install
   ```

3. **Set Up the Frontend**  
   ```bash
   cd frontend
   flutter clean
   flutter pub get
   flutter run
   flutter build --release
   ```

4. **Set Up the Backend**  
   ```bash
   cd backend
   bun install
   bun run dev
   ```

5. **Configure Environment Variables**  
   Set up API keys and database connections in your `.env` file.

6. **Run the Flutter App**  
   ```bash
   flutter run
   ```

---

## 📜 License

This project leverages third-party services and APIs:  
- OpenAI (DeepSeek R1)  
- Google AI (Gemini Flash 2, Gemini Embedding 01)  

---

## 👥 Contributors

- **Tirthankar Nath**  
  - Backend Development (Hono, API integrations, authentication)  
  - Database Management (PostgreSQL, pgvector optimization)  
  - AI & Machine Learning (Vector embeddings, similarity search)  

  - **Jyotirmoy Ganguly** 
  - AI & Machine Learning (LLM integration)
  - Database Management (Redis)  

- **Krishnabh Das**  
  - Frontend Development (Flutter UI, state management)  
  - UI/UX Design (User experience, flow optimization)  

---

## 🔮 Future Enhancements

- **Wearable Integration**: Real-time mental health tracking with devices (e.g., heart rate, sleep monitoring).  
- **Enhanced Personalization**: AI-driven recommendations tailored to your behavior and preferences.  
- **Gamification**: Boost engagement with badges, leaderboards, and challenges.  

