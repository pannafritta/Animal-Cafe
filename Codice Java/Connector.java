import javax.swing.*;
import javax.swing.table.DefaultTableModel;
import java.lang.reflect.InvocationTargetException;
import java.sql.*;

public class Connector {
    private final Connection con;


    public Connector(Connection con) {
        this.con = con;
    }

    public static void main(String[] args) {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver").getDeclaredConstructor().newInstance();
        } catch (InstantiationException | ClassNotFoundException | IllegalAccessException | NoSuchMethodException |
                 InvocationTargetException e) {
            System.out.println("Driver JDBC not found or error loading it: " + e.getMessage());
        }
        try {
            Connection con = DriverManager.getConnection("jdbc:mysql://localhost:3306/acnhcafe", "Anna", "");
            SwingUtilities.invokeLater(() -> {
                Window dbm = new Window(new Connector(con));
                dbm.setVisible(true);
            });
        } catch (SQLException e) {
            System.out.println("Error connecting to database: " + e);
        }
    }

    public void disconnect() throws SQLException {
        if (con != null) {
            con.close();
        }
    }

    public Statement createStatement() throws SQLException {
        return con.createStatement();
    }

    public CallableStatement prepareCall(String s) throws SQLException {
        return con.prepareCall(s);
    }

    public PreparedStatement prepareStatement(String sql) throws SQLException {
        return con.prepareStatement(sql);
    }

    protected void getAnimals(DefaultTableModel model) {
        try {
            Statement stmt = createStatement();
            ResultSet rs = stmt.executeQuery("SELECT * FROM animals");

            while (rs.next()) {
                String name = rs.getString("name");
                String species = rs.getString("species");
                String personality = rs.getString("personality");
                model.addRow(new Object[]{name, species, personality});
            }

            rs.close();
            stmt.close();

        } catch (SQLException e) {
            System.out.println("Errore durante il recupero dei dati: " + e.getMessage());
        }
    }

    protected void getDrinks(DefaultTableModel model) {
        try {
            Statement stmt = createStatement();
            ResultSet rs = stmt.executeQuery("SELECT type, complexity, price, ingredientName, percentage FROM drinks inner join compositions\n" +
                    "    on type = drinkType and complexity = drinkComplexity order by field (type, 'coffee', 'soda', 'tea', 'bubble tea'), complexity;");

            while (rs.next()) {
                String type = rs.getString("type");
                int complexity = rs.getInt("complexity");
                double price = rs.getDouble("price");
                String ingredientName = rs.getString("ingredientName");
                double percentage = rs.getDouble("percentage");
                model.addRow(new Object[]{type, complexity, price, ingredientName, percentage});
            }
            rs.close();
        } catch (SQLException e) {
            System.out.println("Errore durante il recupero dei dati: " + e.getMessage());
        }
    }

    public void getUsers(DefaultTableModel model) {
        try {
            Statement stmt = createStatement();
            ResultSet rs = stmt.executeQuery("SELECT nickname, name, avatar, wallet, points, level FROM users natural join accounts;");

            while (rs.next()) {
                String nickname = rs.getString("nickname");
                String name = rs.getString("name");
                String avatar = rs.getString("avatar");
                int wallet = rs.getInt("wallet");
                int points = rs.getInt("points");
                int level = rs.getInt("level");
                model.addRow(new Object[]{nickname, name, avatar, wallet, points, level});
            }
            rs.close();
            stmt.close();
        } catch (SQLException e) {
            System.out.println("Errore durante il recupero dei dati: " + e.getMessage());
        }
    }

    public void getFurniture(DefaultTableModel model) {
        try {
            Statement stmt = createStatement();
            ResultSet rs = stmt.executeQuery("SELECT * FROM furniture");

            while (rs.next()) {
                String type = rs.getString("type");
                String style = rs.getString("style");
                int price = rs.getInt("price");
                int level = rs.getInt("level");
                model.addRow(new Object[]{type, style, price, level});
            }
            rs.close();
            stmt.close();
        } catch (SQLException e) {
            System.out.println("Errore durante il recupero dei dati: " + e.getMessage());
        }
    }
}