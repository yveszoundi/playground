package apifirst;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

import com.demo.model.User;

public class UserDb {

    private static Map<String, User> userByUsername = new ConcurrentHashMap<>();


    public static void addUser(User user) {
        userByUsername.put(user.getUsername(), user);
    }

    public static User findUser(String username) {
        return userByUsername.get(username);
    }
}
