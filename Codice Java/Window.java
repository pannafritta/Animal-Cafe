import javax.swing.*;
import javax.swing.table.DefaultTableModel;
import javax.swing.table.TableModel;
import java.awt.*;
import java.awt.event.WindowAdapter;
import java.awt.event.WindowEvent;
import java.sql.SQLException;

public class Window extends JFrame {
    private final Connector con;
    private final CardLayout cardLayout;
    private final JPanel cardPanel;

    public Window(Connector con) {
        super("Animal Café");
        this.con = con;

        setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        addWindowListener(new WindowAdapter() {
            @Override
            public void windowClosing(WindowEvent e) {
                try {
                    con.disconnect();
                } catch (SQLException ex) {
                    System.out.println("Error closing connection to database: " + ex.getMessage());
                }
                dispose();
            }
        });
        setSize(800, 600);
        setLayout(new BorderLayout());

        JPanel buttonPanel = new JPanel();
        JButton btnAnimals = new JButton("Show Animals");
        JButton btnDrinks = new JButton("Show Drinks");
        JButton btnUsers = new JButton("Show Users");
        JButton btnFurniture = new JButton("Show Furniture");

        JPanel gamePanel = new JPanel();
        JButton btnNewGame = new JButton("New Game");

        buttonPanel.add(btnAnimals);
        buttonPanel.add(btnDrinks);
        buttonPanel.add(btnUsers);
        buttonPanel.add(btnFurniture);

        gamePanel.add(btnNewGame);

        add(buttonPanel, BorderLayout.NORTH);
        add(gamePanel, BorderLayout.SOUTH);

        cardLayout = new CardLayout();
        cardPanel = new JPanel(cardLayout);

        JPanel defaultPanel = new JPanel();
        JLabel title = new JLabel("<html><h1 style='text-align: center;'>Animal Café</h1><h2 style='text-align: center;'>Database&Demo</h2></html>", SwingConstants.CENTER);
        title.setHorizontalAlignment(JLabel.CENTER);
        title.setVerticalAlignment(JLabel.CENTER);
        defaultPanel.add(title);

        // Pannello per la tabella degli animali
        JPanel animalsPanel = new JPanel(new BorderLayout());
        JTable animalsTable = new JTable(createAnimalsTable());
        animalsPanel.add(new JScrollPane(animalsTable), BorderLayout.CENTER);

        // Pannello per la tabella delle bevande
        JPanel drinksPanel = new JPanel(new BorderLayout());
        JTable drinksTable = new JTable(createDrinksTable());
        drinksPanel.add(new JScrollPane(drinksTable), BorderLayout.CENTER);

        // Pannello per la tabella degli arredi
        JPanel furniturePanel = new JPanel(new BorderLayout());
        JTable furnitureTable = new JTable(createFurnitureTable());
        furniturePanel.add(new JScrollPane(furnitureTable), BorderLayout.CENTER);

        // Pannello per la tabella degli utenti
        JPanel usersPanel = new JPanel(new BorderLayout());
        JTable usersTable = new JTable(createUsersTable());
        usersPanel.add(new JScrollPane(usersTable), BorderLayout.CENTER);

        // Aggiungi i pannelli al cardPanel
        cardPanel.add(defaultPanel, BorderLayout.CENTER);
        cardPanel.add(animalsPanel, "Animals");
        cardPanel.add(drinksPanel, "Drinks");
        cardPanel.add(furniturePanel, "Furniture");
        cardPanel.add(usersPanel, "Users");

        add(cardPanel, BorderLayout.CENTER);

        btnAnimals.addActionListener(e -> cardLayout.show(cardPanel, "Animals"));
        btnDrinks.addActionListener(e -> cardLayout.show(cardPanel, "Drinks"));
        btnUsers.addActionListener(e -> cardLayout.show(cardPanel, "Users"));
        btnFurniture.addActionListener(e -> cardLayout.show(cardPanel, "Furniture"));
        btnNewGame.addActionListener(e -> newGame());
    }

    public void newGame() {
        Game game = new Game(con);

        JFrame gameFrame = new JFrame("Animal Café");

        gameFrame.setDefaultCloseOperation(JFrame.DISPOSE_ON_CLOSE);
        gameFrame.setSize(400, 600);
        gameFrame.setLayout(new BorderLayout());

        JPanel descPanel = new JPanel(new BorderLayout());
        JPanel btnPanel = new JPanel();
        JPanel cupPanel = new JPanel(new GridBagLayout());

        JTextArea text = new JTextArea("""
                Welcome to Animal Café!
                The game consists in serving up drinks for your customers. Each drink is made by one or more ingredients, in a specific quantity.
                To gain more points you have to pour the ingredients as close as possible to the indication written here.""");
        text.setLineWrap(true);
        text.setWrapStyleWord(true);

        JLabel points = new JLabel();

        JButton btnStart = new JButton("Start!");
        JButton btnStop = new JButton("Stop");
        JPanel btnGamePanel = new JPanel();
        btnGamePanel.add(btnStart, BorderLayout.NORTH);
        btnGamePanel.add(btnStop, BorderLayout.SOUTH);

        JScrollPane scroll = new JScrollPane(text);
        scroll.setPreferredSize(new Dimension(200, 200));
        scroll.setViewportBorder(BorderFactory.createLineBorder(Color.black));

        descPanel.add(points, "North");
        descPanel.add(scroll, "Center");
        descPanel.add(btnGamePanel, "South");

        JToggleButton btnPour = new JToggleButton("Pour");
        JButton btnServe = new JButton("Serve");

        btnPour.setEnabled(false);
        btnServe.setEnabled(false);

        btnPanel.add(btnPour);
        btnPanel.add(btnServe);

        cupPanel.setPreferredSize(new Dimension(200, 300));
        cupPanel.setBackground(Color.white);

        Cup cup = new Cup();
        cupPanel.add(cup, new GridBagConstraints());

        gameFrame.add(descPanel, BorderLayout.NORTH);
        gameFrame.add(cupPanel, BorderLayout.CENTER);
        gameFrame.add(btnPanel, BorderLayout.SOUTH);
        gameFrame.setVisible(true);

        Timer pourTimer = new Timer(70, e -> cup.pour());

        btnPour.addActionListener(e -> {
            if (btnPour.isSelected()) {
                pourTimer.start();
            } else {
                pourTimer.stop();
                cup.nextIng();
            }
        });

        btnServe.addActionListener(e -> {
            points.setText(game.closeOrder(cup));
            btnPour.setSelected(false);
            cup.serve();
            text.setText(game.newOrder());
        });

        btnStart.addActionListener(e -> {
            btnPour.setEnabled(true);
            btnServe.setEnabled(true);
            btnStart.setEnabled(false);

            text.setText(game.newGame());
        });

        btnStop.addActionListener(e -> {
            btnPour.setEnabled(false);
            btnServe.setEnabled(false);
            btnStart.setEnabled(true);
            points.setText("");
            text.setText(game.endGame());
        });

    }

    public TableModel createAnimalsTable() {
        DefaultTableModel model = new DefaultTableModel();
        model.addColumn("Name");
        model.addColumn("Species");
        model.addColumn("Personality");
        con.getAnimals(model);
        return model;
    }

    public TableModel createDrinksTable() {
        DefaultTableModel model = new DefaultTableModel();
        model.addColumn("Type");
        model.addColumn("Complexity");
        model.addColumn("Price");
        model.addColumn("Ingredient");
        model.addColumn("Percentage");
        con.getDrinks(model);
        return model;
    }

    public TableModel createFurnitureTable() {
        DefaultTableModel model = new DefaultTableModel();
        model.addColumn("Type");
        model.addColumn("Style");
        model.addColumn("Price");
        model.addColumn("Level");
        con.getFurniture(model);
        return model;
    }

    public TableModel createUsersTable() {
        DefaultTableModel model = new DefaultTableModel();
        model.addColumn("Nickname");
        model.addColumn("Name");
        model.addColumn("Avatar");
        model.addColumn("Wallet");
        model.addColumn("Points");
        model.addColumn("Level");
        con.getUsers(model);
        return model;
    }


}
