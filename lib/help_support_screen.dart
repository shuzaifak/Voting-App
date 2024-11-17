import 'package:flutter/material.dart';
import 'package:voting_system/main.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({Key? key}) : super(key: key);

  @override
  _HelpSupportScreenState createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  String _selectedQuestion = '';

  // Define all FAQ questions and answers
  final Map<String, String> faqResponses = {
    'How do I cast my vote?':
    'To cast your vote: \n1. Go to the "Vote" tab\n2. Select the active election\n3. Choose your candidate\n4. Verify your selection\n5. Submit your vote',

    'What ID do I need to vote?':
    'You need a valid government-issued ID and your registered voter credentials to access the voting system.',

    'How is my vote kept secure?':
    'Your vote is secured through:\n- End-to-end encryption\n- Blockchain technology\n- Anonymous vote recording\n- Multi-factor authentication',

    'Can I change my vote?':
    'No, once a vote is submitted, it cannot be changed. Please review your selection carefully before submitting.',

    'How do I view election results?':
    'Access election results through:\n1. The "Results" tab in the bottom navigation\n2. Select the specific election\n3. View detailed breakdowns and statistics',

    'What happens if I lose internet connection?':
    'If you lose connection while voting, your vote won\'t be submitted. You\'ll need to restart the voting process when reconnected.',

    'How do I report an issue?':
    'To report issues:\n1. Take a screenshot of the problem\n2. Note the time and date\n3. Contact our support team through the app\n4. Provide your voter ID',

    'When do elections close?':
    'Election closing times are listed on each election\'s detail page. Make sure to cast your vote before the deadline.',

    'Can I vote multiple times?':
    'No, the system prevents multiple voting. Each registered voter can only submit one vote per election.',

    'What if I forget my password?':
    'Use the "Forgot Password" link on the login screen to reset your password through your registered email.',

    'How do I update my profile?':
    'Update your profile through:\n1. Click the menu icon\n2. Select "Profile"\n3. Edit your information\n4. Save changes',

    'Is my vote anonymous?':
    'Yes, your vote is completely anonymous. While the system verifies your eligibility, your identity is separated from your vote.',

    'What browsers are supported?':
    'Our system works on all major browsers and mobile devices. For best experience, use the latest version.',

    'How long are results available?':
    'Election results are permanently stored and can be accessed at any time after the election closes.',

    'What if I need accessibility options?':
    'We offer several accessibility features:\n- Screen reader support\n- High contrast mode\n- Text size adjustment\n- Voice commands',

    'Can I vote early?':
    'Yes, you can vote any time between the election start and end dates listed on the election detail page.',

    'How do I verify my registration?':
    'Verify your registration in the Profile section. Your status should show as "Verified" with a green checkmark.',

    'What time zone are deadlines in?':
    'All election deadlines are displayed in your local time zone, as detected by your device.',

    'How do I contact human support?':
    'For human support:\n1. Email: support@votingsystem.com\n2. Phone: 1-800-VOTE-HELP\n3. Available Monday-Friday, 9AM-5PM',

    'What happens after I vote?':
    'After voting:\n1. You\'ll receive a confirmation receipt\n2. Your vote is securely recorded\n3. You can view the election status\n4. Results available after closing',
  };

  @override
  void initState() {
    super.initState();
    // Add initial bot message
    _messages.add(
      ChatMessage(
        text: "Hello! Please select a question from the list below and I'll help you find the answer.",
        isBot: true,
      ),
    );
  }

  void _handleQuestionSelected(String question) {
    setState(() {
      _selectedQuestion = question;
      _messages.add(ChatMessage(text: question, isBot: false));
      _messages.add(ChatMessage(text: faqResponses[question]!, isBot: true));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Help & Support',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primaryBlue,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessage(message);
              },
            ),
          ),
          _buildQuestionSelector(),
        ],
      ),
    );
  }

  Widget _buildMessage(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment:
        message.isBot ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (message.isBot)
            const CircleAvatar(
              backgroundColor: AppColors.primaryBlue,
              child: Icon(Icons.support_agent, color: Colors.white),
            ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isBot
                    ? Colors.grey[200]
                    : AppColors.primaryBlue.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: message.isBot ? Colors.black87 : Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (!message.isBot)
            const CircleAvatar(
              backgroundColor: AppColors.primaryBlue,
              child: Icon(Icons.person, color: Colors.white),
            ),
        ],
      ),
    );
  }

  Widget _buildQuestionSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -2),
            blurRadius: 6,
            color: Colors.black.withOpacity(0.1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primaryBlue),
              borderRadius: BorderRadius.circular(25),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedQuestion.isEmpty ? null : _selectedQuestion,
                hint: const Text('Select a question...'),
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down, color: AppColors.primaryBlue),
                items: faqResponses.keys.map((String question) {
                  return DropdownMenuItem<String>(
                    value: question,
                    child: Text(
                      question,
                      style: const TextStyle(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    _handleQuestionSelected(newValue);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

class ChatMessage {
  final String text;
  final bool isBot;

  ChatMessage({required this.text, required this.isBot});
}