package apifirst;

import java.net.URI;
import java.util.concurrent.ThreadLocalRandom;

import javax.servlet.http.HttpServletRequest;

import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.context.request.NativeWebRequest;

import com.demo.api.UserApi;
import com.demo.model.User;

@RestController
class UserApiController implements UserApi {

    private final NativeWebRequest nativeWebRequest;

    UserApiController(NativeWebRequest nativeWebRequest) {
        this.nativeWebRequest = nativeWebRequest;
    }

    @Override
    public ResponseEntity<User> getUserByName(String username) {
        User user = new User();
        user.id(1L).email("john.doe@email.com").firstName("john").lastName("doe").password("password").phone("647-123-4567").username(username).userStatus(1);
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        ResponseEntity<User> response = new ResponseEntity<>(user, headers,  HttpStatus.OK);
        return response;
    }

    @Override
    public ResponseEntity<Void> createUser(User newUser) {
        newUser.setId(ThreadLocalRandom.current().nextLong());
        HttpServletRequest request = nativeWebRequest.getNativeRequest(HttpServletRequest.class);
        URI location = URI.create(String.format("%s/%d", request.getRequestURI(), newUser.getId()));

        return ResponseEntity.created(location).build();
    }
}
