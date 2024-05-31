import java.sql.*;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalTime;

public class Game {
    private final Connector con;
    private int gid = 0;
    private int oid = 0;
    private double[] percentages = new double[3];
    private int pointsLost = 0;
    private Instant start;

    public Game(Connector con) {
        this.con = con;
    }

    public String newGame() {
        start = Instant.now();
        try {
            CallableStatement cStm = con.prepareCall("{call createGame(?, ?)}");
            cStm.registerOutParameter(2, Types.INTEGER);
            cStm.setString(1, "default");
            cStm.setInt(2, gid);
            cStm.execute();
            gid = cStm.getInt(2);
            cStm.close();
            return newOrder();
        } catch (SQLException e) {
            return "Error generating game: " + e;
        }
    }

    public String newOrder() {
        try {
            CallableStatement cStm = con.prepareCall("{call generateOrder(?, ?)}");
            cStm.registerOutParameter(2, Types.INTEGER);
            cStm.setInt(1, gid);
            cStm.setInt(2, oid);
            cStm.execute();
            oid = cStm.getInt(2);
            cStm.close();
            return writeOrder(oid);
        } catch (SQLException e) {
            return "Error generating order: " + e;
        }
    }

    private String writeOrder(int oid) {
        try {
            StringBuilder result = new StringBuilder();

            String sql = "select drinkType, drinkComplexity, animalName from orders where id = ?";
            PreparedStatement prepared = con.prepareStatement(sql);
            prepared.setInt(1, oid);
            ResultSet rs = prepared.executeQuery();

            String type = null;
            String complexity = null;
            if (rs.next()) {
                type = rs.getString("drinkType");
                complexity = rs.getString("drinkComplexity");
                String customer = rs.getString("animalName");
                result = new StringBuilder("Client: " + customer + "\n" + "Drink: " + type + " " + complexity + "\n");
            }

            sql = "select ingredientName, percentage from compositions where drinkType = ? and drinkComplexity = ?";
            prepared = con.prepareStatement(sql);
            prepared.setString(1, type);
            prepared.setString(2, complexity);
            rs = prepared.executeQuery();

            int i = 0;
            percentages = new double[]{0, 0, 0};
            while (rs.next()) {
                percentages[i] = rs.getDouble("percentage");
                result.append(++i).append("° ingredient: ").append(rs.getString("ingredientName"))
                        .append(" -> ").append((rs.getDouble("percentage")) * 100).append("% \n");
            }

            result.append("\n[Legend: 1° -> BLUE, 2° -> ORANGE, 3° -> YELLOW]");
            rs.close();
            prepared.close();
            return result.toString();

        } catch (SQLException e) {
            return "Error getting order: " + e.getMessage();
        }
    }

    public String closeOrder(Cup cup) {
        StringBuilder stars = new StringBuilder("Last order points: ");
        int[] heights = cup.getHeights();
        int points = 0;
        for (int i = 0; i < percentages.length; i++) {
            if (percentages[i] > 0) {
                if (Math.abs((double) heights[i] / 225 - percentages[i]) <= 0.05) {
                    stars.append("★");
                    points += 1;
                } else {
                    pointsLost += 1;
                    stars.append("☆");
                }
            }
        }
        try {
            CallableStatement cStm = con.prepareCall("{call updateOrder(?, ?)}");
            cStm.setInt(1, oid);
            cStm.setInt(2, points);
            cStm.execute();
            cStm.close();
        } catch (SQLException e) {
            System.out.println("Error updating order: " + e.getMessage());
        }
        return stars.toString();
    }

    public String endGame() {
        Instant end = Instant.now();
        Duration d = Duration.between(start, end);
        Time duration = Time.valueOf(LocalTime.of(((int) d.toHours())%24, ((int) d.toMinutes())%60, ((int) d.toSeconds())%60));
        String result = "";

        try (CallableStatement cStm = con.prepareCall("{call endGame(?, ?)}")) {
            cStm.setInt(1, gid);
            cStm.setTime(2, duration);
            boolean hadResults = cStm.execute();
            while (hadResults) {
                try (ResultSet rs = cStm.getResultSet()) {
                    while (rs.next()) {
                        int gamePoints = rs.getInt(4);
                        result = "Total game points: " + gamePoints + "/" + (gamePoints + pointsLost) +
                                "\nTotal profits: " + rs.getInt(5) +
                                "\nDuration: " + duration +
                                "\nGame saved successfully for user.";
                    }
                }
                hadResults = cStm.getMoreResults();
            }
            return result;
        } catch (SQLException e) {
            return "Error ending game: " + e.getMessage();
        }
    }
}
