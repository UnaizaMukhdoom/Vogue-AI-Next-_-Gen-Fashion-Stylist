import React, { useState, useEffect } from 'react';
import { collection, getDocs, query, where } from 'firebase/firestore';
import { db } from '../config/firebase';
import {
  Users,
  FileText,
  MessageSquare,
  TrendingUp,
  Shirt,
  Gem,
} from 'lucide-react';
import './Dashboard.css';

const Dashboard = () => {
  const [stats, setStats] = useState({
    totalUsers: 0,
    totalAnalyses: 0,
    totalChats: 0,
    totalClothing: 0,
    totalJewelry: 0,
    totalQuestionnaires: 0,
  });
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchStats();
  }, []);

  const fetchStats = async () => {
    try {
      // Fetch users count
      const usersSnapshot = await getDocs(collection(db, 'users'));
      const totalUsers = usersSnapshot.size;

      // Fetch analyses count
      const analysesSnapshot = await getDocs(collection(db, 'analyses'));
      const totalAnalyses = analysesSnapshot.size;

      // Fetch chats count (from chatbot interactions)
      const chatsSnapshot = await getDocs(collection(db, 'chatbot_interactions'));
      const totalChats = chatsSnapshot.size;

      // Fetch clothing items count
      const clothingSnapshot = await getDocs(collection(db, 'wardrobe'));
      const totalClothing = clothingSnapshot.size;

      // Fetch jewelry recommendations (from face shape analyses)
      const jewelryQuery = query(
        collection(db, 'analyses'),
        where('face_shape', '!=', null)
      );
      const jewelrySnapshot = await getDocs(jewelryQuery);
      const totalJewelry = jewelrySnapshot.size;

      // Fetch questionnaires count
      const questionnairesSnapshot = await getDocs(collection(db, 'questionnaires'));
      const totalQuestionnaires = questionnairesSnapshot.size;

      setStats({
        totalUsers,
        totalAnalyses,
        totalChats,
        totalClothing,
        totalJewelry,
        totalQuestionnaires,
      });
    } catch (error) {
      console.error('Error fetching stats:', error);
    } finally {
      setLoading(false);
    }
  };

  const statCards = [
    {
      title: 'Total Users',
      value: stats.totalUsers,
      icon: Users,
      color: '#3498db',
    },
    {
      title: 'Color Analyses',
      value: stats.totalAnalyses,
      icon: FileText,
      color: '#9b59b6',
    },
    {
      title: 'Chatbot Interactions',
      value: stats.totalChats,
      icon: MessageSquare,
      color: '#e74c3c',
    },
    {
      title: 'Clothing Items',
      value: stats.totalClothing,
      icon: Shirt,
      color: '#f39c12',
    },
    {
      title: 'Jewelry Recommendations',
      value: stats.totalJewelry,
      icon: Gem,
      color: '#1abc9c',
    },
    {
      title: 'Questionnaires',
      value: stats.totalQuestionnaires,
      icon: TrendingUp,
      color: '#34495e',
    },
  ];

  if (loading) {
    return (
      <div className="dashboard-loading">
        <div>Loading dashboard...</div>
      </div>
    );
  }

  return (
    <div className="dashboard">
      <div className="dashboard-header">
        <h1>Dashboard</h1>
        <p>Welcome to VOGUE AI Admin Panel</p>
      </div>

      <div className="stats-grid">
        {statCards.map((stat, index) => {
          const Icon = stat.icon;
          return (
            <div key={index} className="stat-card">
              <div className="stat-icon" style={{ backgroundColor: `${stat.color}20` }}>
                <Icon size={24} color={stat.color} />
              </div>
              <div className="stat-content">
                <div className="stat-value">{stat.value}</div>
                <div className="stat-title">{stat.title}</div>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
};

export default Dashboard;

