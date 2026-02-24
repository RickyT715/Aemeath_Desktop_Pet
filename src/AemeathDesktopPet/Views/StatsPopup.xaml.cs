using System.Windows;
using AemeathDesktopPet.Models;

namespace AemeathDesktopPet.Views;

public partial class StatsPopup : Window
{
    public StatsPopup(AemeathStats stats)
    {
        InitializeComponent();
        UpdateDisplay(stats);
    }

    private void UpdateDisplay(AemeathStats stats)
    {
        // Stat bars (width as percentage of container)
        MoodValue.Text = $"{stats.Mood:F0}/100";
        MoodBar.Width = Math.Max(0, stats.Mood / 100.0 * 260);

        EnergyValue.Text = $"{stats.Energy:F0}/100";
        EnergyBar.Width = Math.Max(0, stats.Energy / 100.0 * 260);

        AffectionValue.Text = $"{stats.Affection:F0}/100";
        AffectionBar.Width = Math.Max(0, stats.Affection / 100.0 * 260);

        // Lifetime stats
        DaysTogetherText.Text = $"\u2726 Days together: {stats.DaysTogether}";
        TotalChatsText.Text = $"\u2726 Chats: {stats.TotalChats}";
        TotalPlanesText.Text = $"\u2708 Paper planes thrown: {stats.TotalPaperPlanes}";
        TotalSongsText.Text = $"\u266A Songs sung: {stats.TotalSongs}";
        TotalPetsText.Text = $"\u2665 Times petted: {stats.TotalPets}";

        // Aemeath's comment based on stats
        AemeathComment.Text = OfflineResponses.GetContextual(stats, DateTime.Now);
    }

    private void Close_Click(object sender, RoutedEventArgs e)
    {
        Close();
    }
}
